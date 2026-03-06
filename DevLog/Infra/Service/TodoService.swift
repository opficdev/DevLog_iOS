//
//  TodoService.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import FirebaseAuth
import FirebaseFirestore

final class TodoService {
    private let store = Firestore.firestore()
    private let encoder = Firestore.Encoder()
    private let logger = Logger(category: "TodoService")
    
    func fetchTodos(
        _ query: TodoQuery,
        cursor: TodoCursorDTO?
    ) async throws -> TodoPageResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let trimmedKeyword = query.keyword?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let logComponents: [String?] = [
            "sortTarget=\(query.sortTarget.fieldName)",
            "sortOrder=\(query.sortOrder == .latest ? "latest" : "oldest")",
            query.keyword != nil ? "keywordLength=\(trimmedKeyword.count)" : nil,
            query.kind != nil ? "kind=\(query.kind!.rawValue)" : nil,
            query.isPinned != nil ? "pinned=\(query.isPinned!)" : nil,
            query.completionFilter.isCompletedValue != nil ? "completed=\(query.completionFilter.isCompletedValue!)" : nil,
            query.dueDateFilter != .all ? "dueDateFilter=\(query.dueDateFilter)" : nil,
            query.createdAtFrom != nil ? "createdAtFrom=\(query.createdAtFrom!)" : nil,
            query.createdAtTo != nil ? "createdAtTo=\(query.createdAtTo!)" : nil,
            "pageSize=\(query.pageSize)",
            query.fetchAllPages ? "fetchAllPages=true" : nil,
            cursor != nil ? "cursor=\(cursor!)" : nil
        ]
        logger.info("Fetching todo page: \(logComponents.compactMap { $0 }.joined(separator: ", "))")

        var firestoreQuery: Query = makeOrderedQuery(uid: uid, query: query)

        if let kind = query.kind {
            firestoreQuery = firestoreQuery.whereField("kind", isEqualTo: kind.rawValue)
        }

        if let isPinned = query.isPinned {
            firestoreQuery = firestoreQuery.whereField("isPinned", isEqualTo: isPinned)
        }

        if let isCompleted = query.completionFilter.isCompletedValue {
            firestoreQuery = firestoreQuery.whereField("isCompleted", isEqualTo: isCompleted)
        }

        switch query.dueDateFilter {
        case .all:
            break
        case .withDueDate:
            firestoreQuery = firestoreQuery.whereField(
                "dueDate",
                isGreaterThan: Timestamp(date: Date(timeIntervalSince1970: 0))
            )
        case .withoutDueDate:
            firestoreQuery = firestoreQuery.whereField("dueDate", isEqualTo: NSNull())
        }

        if let createdAtFrom = query.createdAtFrom {
            firestoreQuery = firestoreQuery.whereField(
                "createdAt",
                isGreaterThanOrEqualTo: Timestamp(date: createdAtFrom)
            )
        }

        if let createdAtTo = query.createdAtTo {
            firestoreQuery = firestoreQuery.whereField(
                "createdAt",
                isLessThan: Timestamp(date: createdAtTo)
            )
        }

        if trimmedKeyword.isEmpty {
            if query.fetchAllPages {
                var allItems: [TodoResponse] = []
                var pageCursor = cursor

                while true {
                    var pageQuery = firestoreQuery
                    if let pageCursor {
                        pageQuery = pageQuery.start(after: cursorValues(for: query, cursor: pageCursor))
                    }

                    pageQuery = pageQuery.limit(to: query.pageSize)
                    let snapshot = try await pageQuery.getDocuments()
                    allItems.append(contentsOf: snapshot.documents.compactMap { makeResponse(from: $0) })

                    guard snapshot.documents.count == query.pageSize else {
                        break
                    }

                    guard let lastDocument = snapshot.documents.last,
                          let nextCursor = makeCursor(
                            from: lastDocument,
                            query: query
                          ) else {
                        break
                    }

                    pageCursor = nextCursor
                }

                return TodoPageResponse(items: allItems, nextCursor: nil)
            }

            if let cursor {
                firestoreQuery = firestoreQuery.start(after: cursorValues(for: query, cursor: cursor))
            }

            firestoreQuery = firestoreQuery.limit(to: query.pageSize)
            let snapshot = try await firestoreQuery.getDocuments()
            let items = snapshot.documents.compactMap { makeResponse(from: $0) }
            let nextCursor = snapshot.documents.last.flatMap {
                makeCursor(from: $0, query: query)
            }

            return TodoPageResponse(items: items, nextCursor: nextCursor)
        }

        let snapshot = try await firestoreQuery.getDocuments()
        let todos = snapshot.documents.compactMap { makeResponse(from: $0) }

        let filtered = todos.filter { todo in
            todo.title.localizedCaseInsensitiveContains(trimmedKeyword)
                || todo.content.localizedCaseInsensitiveContains(trimmedKeyword)
                || todo.tags.contains { $0.localizedCaseInsensitiveContains(trimmedKeyword) }
        }

        return TodoPageResponse(items: filtered, nextCursor: nil)
    }

    func upsertTodo(request: TodoRequest) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Upserting todo: \(request.id)")
        
        do {
            let collection = store.collection("users/\(uid)/todoLists/")
            let docRef = collection.document(request.id)
            var data = try encoder.encode(request)
            data.removeValue(forKey: TodoFieldKey.id.rawValue)
            if request.completedAt == nil {
                data[TodoFieldKey.completedAt.rawValue] = NSNull()
            }
            if request.dueDate == nil {
                data[TodoFieldKey.dueDate.rawValue] = NSNull()
            }
            try await docRef.setData(data, merge: true)
            
            logger.info("Successfully upserted todo")
        } catch {
            logger.error("Failed to upsert todo", error: error)
            throw error
        }
    }
    
    func deleteTodo(todoID: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Deleting todo: \(todoID)")
        
        do {
            let collection = store.collection("users/\(uid)/todoLists/")
            let docRef = collection.document(todoID)
            try await docRef.delete()
            
            logger.info("Successfully deleted todo")
        } catch {
            logger.error("Failed to delete todo", error: error)
            throw error
        }
    }

    func fetchTodo(todoID: String) async throws -> TodoResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Fetching todo: \(todoID) for user: \(uid)")

        do {
            let docRef = store.collection("users/\(uid)/todoLists/").document(todoID)
            let snapshot = try await docRef.getDocument()
            guard snapshot.exists, let todo = makeResponse(from: snapshot) else {
                throw FirestoreError.dataNotFound("Todo")
            }

            logger.info("Successfully fetched todo")
            return todo
        } catch {
            logger.error("Failed to fetch todo", error: error)
            throw error
        }
    }
}

private extension TodoService {
    func makeOrderedQuery(uid: String, query: TodoQuery) -> Query {
        let collection = store.collection("users/\(uid)/todoLists/")

        switch query.sortTarget {
        case .dueDate:
            return collection
                .order(by: query.sortTarget.fieldName, descending: query.sortOrder.isDescending)
                .order(by: "updatedAt", descending: true)
                .order(by: FieldPath.documentID())
        case .createdAt, .updatedAt:
            return collection
                .order(by: query.sortTarget.fieldName, descending: query.sortOrder.isDescending)
                .order(by: FieldPath.documentID())
        }
    }

    func cursorValues(
        for query: TodoQuery,
        cursor: TodoCursorDTO
    ) -> [Any] {
        let primaryValue: Any = cursor.primarySortDate.map { Timestamp(date: $0) } ?? NSNull()

        switch query.sortTarget {
        case .dueDate:
            guard let secondarySortDate = cursor.secondarySortDate else {
                return [primaryValue, cursor.documentID]
            }
            return [
                primaryValue,
                Timestamp(date: secondarySortDate),
                cursor.documentID
            ]
        case .createdAt, .updatedAt:
            return [
                primaryValue,
                cursor.documentID
            ]
        }
    }

    func makeCursor(
        from document: QueryDocumentSnapshot,
        query: TodoQuery
    ) -> TodoCursorDTO? {
        let data = document.data()
        let orderField = query.sortTarget.fieldName
        let primarySortDate: Date?
        let secondarySortDate: Date?

        if let timestamp = data[orderField] as? Timestamp {
            primarySortDate = timestamp.dateValue()
        } else if data[orderField] is NSNull {
            primarySortDate = nil
        } else {
            return nil
        }

        switch query.sortTarget {
        case .dueDate:
            guard let updatedAt = data["updatedAt"] as? Timestamp else {
                return nil
            }
            secondarySortDate = updatedAt.dateValue()
        case .createdAt, .updatedAt:
            secondarySortDate = nil
        }

        return TodoCursorDTO(
            primarySortDate: primarySortDate,
            secondarySortDate: secondarySortDate,
            documentID: document.documentID
        )
    }

    func makeResponse(from snapshot: QueryDocumentSnapshot) -> TodoResponse? {
        makeResponse(documentID: snapshot.documentID, data: snapshot.data())
    }

    func makeResponse(from snapshot: DocumentSnapshot) -> TodoResponse? {
        guard let data = snapshot.data() else {
            return nil
        }
        return makeResponse(documentID: snapshot.documentID, data: data)
    }

    func makeResponse(documentID: String, data: [String: Any]) -> TodoResponse? {
        guard
            let isPinned = data[TodoFieldKey.isPinned.rawValue] as? Bool,
            let isCompleted = data[TodoFieldKey.isCompleted.rawValue] as? Bool,
            let isChecked = data[TodoFieldKey.isChecked.rawValue] as? Bool,
            let title = data[TodoFieldKey.title.rawValue] as? String,
            let content = data[TodoFieldKey.content.rawValue] as? String,
            let createdAtTimestamp = data[TodoFieldKey.createdAt.rawValue] as? Timestamp,
            let updatedAtTimestamp = data[TodoFieldKey.updatedAt.rawValue] as? Timestamp,
            let tags = data[TodoFieldKey.tags.rawValue] as? [String],
            let kind = data[TodoFieldKey.kind.rawValue] as? String else {
            return nil
        }

        let completedAt = (data[TodoFieldKey.completedAt.rawValue] as? Timestamp)?.dateValue()
        let dueDate = (data[TodoFieldKey.dueDate.rawValue] as? Timestamp)?.dateValue()
        return TodoResponse(
            id: documentID,
            isPinned: isPinned,
            isCompleted: isCompleted,
            isChecked: isChecked,
            title: title,
            content: content,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            completedAt: completedAt,
            dueDate: dueDate,
            tags: tags,
            kind: kind
        )
    }

    enum TodoFieldKey: String {
        case id
        case isPinned
        case isCompleted
        case isChecked
        case title
        case content
        case createdAt
        case updatedAt
        case completedAt
        case dueDate
        case tags
        case kind
    }
}
