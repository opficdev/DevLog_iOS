//
//  TodoQueryServiceImpl.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import FirebaseAuth
import FirebaseFirestore
import Core
import Data

final class TodoQueryServiceImpl: TodoQueryService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.TodoServiceImpl"

        enum Code: Int {
            case fetchTodos = 1
            case fetchTodo = 5
            case fetchReferences = 6
        }
    }

    private let store = FirebaseConfiguration.firestore
    private let logger = Logger(category: "TodoServiceImpl")

    // swiftlint:disable function_body_length
    func fetchTodos(
        _ query: TodoQuery,
        cursor: TodoCursorDTO?
    ) async throws -> TodoPageResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        let keyword = query.keyword?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        logger.info("Fetching todo page: \(makeLogMessage(query: query, keyword: keyword, cursor: cursor))")

        do {
            var firestoreQuery = makeQuery(uid: uid, query: query)
            firestoreQuery = makeFilteredQuery(firestoreQuery, queryOptions: query)

            if keyword.isEmpty {
                if query.fetchAllPages {
                    return try await fetchAllPages(
                        firestoreQuery,
                        queryOptions: query,
                        cursor: cursor
                    )
                }

                if let cursor {
                    guard let values = TodoQueryCursorMapper.makeValues(query: query, cursor: cursor) else {
                        logger.error("Failed to build cursor values for todo fetch.")
                        return TodoPageResponse(items: [], nextCursor: nil)
                    }
                    firestoreQuery = firestoreQuery.start(after: values)
                }

                let snapshot = try await firestoreQuery.limit(to: query.pageSize).getDocuments()
                let items = snapshot.documents.compactMap(TodoDocumentMapper.makeResponse)
                let nextCursor = snapshot.documents.last.flatMap {
                    TodoQueryCursorMapper.makeCursor(document: $0, query: query)
                }
                return TodoPageResponse(items: items, nextCursor: nextCursor)
            }

            let snapshot = try await firestoreQuery.getDocuments()
            let todos = snapshot.documents.compactMap(TodoDocumentMapper.makeResponse)
            let numberKeyword = TodoSearchMatching.normalizedNumberKeyword(from: keyword) ?? keyword
            let items = todos.filter {
                TodoSearchMatching.matches($0, keyword: keyword, numberKeyword: numberKeyword)
            }
            return TodoPageResponse(items: items, nextCursor: nil)
        } catch {
            logger.error("Failed to fetch todos", error: error)
            record(error, code: .fetchTodos)
            throw error
        }
    }
    // swiftlint:enable function_body_length

    func fetchTodo(todoId: String) async throws -> TodoResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        logger.info("Fetching todo")
        do {
            let snapshot = try await store.collection(FirestorePath.todos(uid))
                .whereField(FieldPath.documentID(), isEqualTo: todoId)
                .whereField(TodoDocumentFieldKey.deletedAt.rawValue, isEqualTo: NSNull())
                .limit(to: 1)
                .getDocuments()
            guard
                let document = snapshot.documents.first,
                let response = TodoDocumentMapper.makeResponse(document)
            else {
                throw FirestoreError.dataNotFound("Todo")
            }
            logger.info("Successfully fetched todo")
            return response
        } catch {
            logger.error("Failed to fetch todo", error: error)
            record(error, code: .fetchTodo)
            throw error
        }
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReferenceResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        let uniqueNumbers = Array(Set(numbers)).sorted()
        guard !uniqueNumbers.isEmpty else { return [:] }

        do {
            let collection = store.collection(FirestorePath.todos(uid))
            let snapshots = try await withThrowingTaskGroup(of: [QueryDocumentSnapshot].self) { group in
                for chunk in uniqueNumbers.chunked(maxCount: 10) {
                    group.addTask {
                        try await collection
                            .whereField(TodoDocumentFieldKey.number.rawValue, in: chunk)
                            .whereField(TodoDocumentFieldKey.deletedAt.rawValue, isEqualTo: NSNull())
                            .getDocuments()
                            .documents
                    }
                }

                var documents = [QueryDocumentSnapshot]()
                for try await chunkDocuments in group {
                    documents.append(contentsOf: chunkDocuments)
                }
                return documents
            }

            return snapshots.reduce(into: [Int: TodoReferenceResponse]()) { result, document in
                let data = document.data()
                guard
                    data[TodoDocumentFieldKey.deletedAt.rawValue] is NSNull,
                    let response = TodoDocumentMapper.makeResponse(document)
                else {
                    return
                }
                result[response.number] = .init(
                    id: response.id,
                    number: response.number,
                    title: response.title,
                    category: response.category
                )
            }
        } catch {
            logger.error("Failed to fetch todo references", error: error)
            record(error, code: .fetchReferences)
            throw error
        }
    }

    private func makeQuery(uid: String, query: TodoQuery) -> Query {
        var collection: Query = store.collection(FirestorePath.todos(uid))
        if !query.includesDeleted {
            collection = collection.whereField(TodoDocumentFieldKey.deletedAt.rawValue, isEqualTo: NSNull())
        }

        let fieldName = TodoQueryCursorMapper.fieldName(for: query.sortTarget)
        switch query.sortTarget {
        case .dueDate:
            return collection
                .order(by: fieldName, descending: TodoQueryCursorMapper.isDescending(query.sortOrder))
                .order(by: TodoDocumentFieldKey.updatedAt.rawValue, descending: true)
                .order(by: FieldPath.documentID())
        case .createdAt, .completedAt, .deletedAt, .updatedAt:
            return collection
                .order(by: fieldName, descending: TodoQueryCursorMapper.isDescending(query.sortOrder))
                .order(by: FieldPath.documentID())
        }
    }

    private func makeFilteredQuery(_ query: Query, queryOptions: TodoQuery) -> Query {
        var query = query
        if let categoryId = queryOptions.categoryId {
            query = query.whereField(TodoDocumentFieldKey.category.rawValue, isEqualTo: categoryId)
        }
        if queryOptions.isPinned {
            query = query.whereField(TodoDocumentFieldKey.isPinned.rawValue, isEqualTo: true)
        }
        if let isCompleted = TodoQueryCursorMapper.isCompletedValue(for: queryOptions.completionFilter) {
            query = query.whereField(TodoDocumentFieldKey.isCompleted.rawValue, isEqualTo: isCompleted)
        }
        switch queryOptions.dueDateFilter {
        case .all:
            break
        case .withDueDate:
            query = query.whereField(
                TodoDocumentFieldKey.dueDate.rawValue,
                isGreaterThan: Timestamp(date: Date(timeIntervalSince1970: 0))
            )
        case .withoutDueDate:
            query = query.whereField(TodoDocumentFieldKey.dueDate.rawValue, isEqualTo: NSNull())
        }
        if let sortDateFrom = queryOptions.sortDateFrom {
            query = query.whereField(
                TodoQueryCursorMapper.fieldName(for: queryOptions.sortTarget),
                isGreaterThanOrEqualTo: Timestamp(date: sortDateFrom)
            )
        }
        if let sortDateTo = queryOptions.sortDateTo {
            query = query.whereField(
                TodoQueryCursorMapper.fieldName(for: queryOptions.sortTarget),
                isLessThan: Timestamp(date: sortDateTo)
            )
        }
        return query
    }

    private func fetchAllPages(
        _ query: Query,
        queryOptions: TodoQuery,
        cursor: TodoCursorDTO?
    ) async throws -> TodoPageResponse {
        var items = [TodoResponse]()
        var pageCursor = cursor

        while true {
            var pageQuery = query
            if let pageCursor {
                guard let values = TodoQueryCursorMapper.makeValues(
                    query: queryOptions,
                    cursor: pageCursor
                ) else {
                    logger.error("Failed to build cursor values for paginated todo fetch.")
                    break
                }
                pageQuery = pageQuery.start(after: values)
            }

            let snapshot = try await pageQuery.limit(to: queryOptions.pageSize).getDocuments()
            items.append(contentsOf: snapshot.documents.compactMap(TodoDocumentMapper.makeResponse))
            guard snapshot.documents.count == queryOptions.pageSize else { break }
            guard
                let document = snapshot.documents.last,
                let nextCursor = TodoQueryCursorMapper.makeCursor(document: document, query: queryOptions)
            else {
                break
            }
            pageCursor = nextCursor
        }

        return TodoPageResponse(items: items, nextCursor: nil)
    }

    private func makeLogMessage(
        query: TodoQuery,
        keyword: String,
        cursor: TodoCursorDTO?
    ) -> String {
        let components: [String?] = [
            "sortTarget=\(TodoQueryCursorMapper.fieldName(for: query.sortTarget))",
            "sortOrder=\(query.sortOrder == .latest ? "latest" : "oldest")",
            query.keyword != nil ? "keywordLength=\(keyword.count)" : nil,
            query.categoryId != nil ? "category=\(query.categoryId!)" : nil,
            query.isPinned ? "pinned=true" : nil,
            TodoQueryCursorMapper.isCompletedValue(for: query.completionFilter).map { "completed=\($0)" },
            query.dueDateFilter != .all ? "dueDateFilter=\(query.dueDateFilter)" : nil,
            query.sortDateFrom != nil ? "sortDateFrom=\(query.sortDateFrom!)" : nil,
            query.sortDateTo != nil ? "sortDateTo=\(query.sortDateTo!)" : nil,
            query.includesDeleted ? "includesDeleted=true" : nil,
            "pageSize=\(query.pageSize)",
            query.fetchAllPages ? "fetchAllPages=true" : nil,
            cursor != nil ? "cursor=\(cursor!)" : nil
        ]
        return components.compactMap { $0 }.joined(separator: ", ")
    }

    private static func record(_ error: Error, code: CrashlyticsError.Code) {
        FirebaseCrashlyticsHelper.record(
            error,
            domain: "\(CrashlyticsError.domain).\(code)",
            code: code.rawValue
        )
    }

    private func record(_ error: Error, code: CrashlyticsError.Code) {
        Self.record(error, code: code)
    }
}
