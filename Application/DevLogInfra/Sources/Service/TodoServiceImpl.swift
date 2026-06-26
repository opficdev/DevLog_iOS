//
//  TodoServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 6/2/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import DevLogCore
import DevLogData

final class TodoServiceImpl: TodoService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.TodoServiceImpl"

        enum Code: Int {
            case fetchTodos = 1
            case upsertTodo
            case deleteTodo
            case undoDeleteTodo
            case fetchTodo
            case fetchReferences
        }
    }

    private enum FunctionName: String {
        case requestTodoDeletion
        case undoTodoDeletion
    }

    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let encoder = Firestore.Encoder()
    private let logger = Logger(category: "TodoServiceImpl")
    
    // swiftlint:disable function_body_length
    func fetchTodos(
        _ query: TodoQuery,
        cursor: TodoCursorDTO?
    ) async throws -> TodoPageResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        let trimmedKeyword = query.keyword?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let logComponents: [String?] = [
            "sortTarget=\(query.sortTarget.fieldName)",
            "sortOrder=\(query.sortOrder == .latest ? "latest" : "oldest")",
            query.keyword != nil ? "keywordLength=\(trimmedKeyword.count)" : nil,
            query.categoryId != nil ? "category=\(query.categoryId!)" : nil,
            query.isPinned ? "pinned=true" : nil,
            query.completionFilter.isCompletedValue != nil
                ? "completed=\(query.completionFilter.isCompletedValue!)"
                : nil,
            query.dueDateFilter != .all ? "dueDateFilter=\(query.dueDateFilter)" : nil,
            query.sortDateFrom != nil ? "sortDateFrom=\(query.sortDateFrom!)" : nil,
            query.sortDateTo != nil ? "sortDateTo=\(query.sortDateTo!)" : nil,
            query.includesDeleted ? "includesDeleted=true" : nil,
            "pageSize=\(query.pageSize)",
            query.fetchAllPages ? "fetchAllPages=true" : nil,
            cursor != nil ? "cursor=\(cursor!)" : nil
        ]
        logger.info("Fetching todo page: \(logComponents.compactMap { $0 }.joined(separator: ", "))")

        do {
            var firestoreQuery = makeQuery(uid: uid, query: query)

            if let categoryId = query.categoryId {
                firestoreQuery = firestoreQuery.whereField(
                    TodoFieldKey.category.rawValue,
                    isEqualTo: categoryId
                )
            }

            if query.isPinned {
                firestoreQuery = firestoreQuery.whereField("isPinned", isEqualTo: true)
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

            if let sortDateFrom = query.sortDateFrom {
                firestoreQuery = firestoreQuery.whereField(
                    query.sortTarget.fieldName,
                    isGreaterThanOrEqualTo: Timestamp(date: sortDateFrom)
                )
            }

            if let sortDateTo = query.sortDateTo {
                firestoreQuery = firestoreQuery.whereField(
                    query.sortTarget.fieldName,
                    isLessThan: Timestamp(date: sortDateTo)
                )
            }

            if trimmedKeyword.isEmpty {
                if query.fetchAllPages {
                    var allItems: [TodoResponse] = []
                    var pageCursor = cursor

                    while true {
                        var pageQuery = firestoreQuery
                        if let pageCursor {
                            guard let cursorValues = cursorValues(
                                for: query,
                                cursor: pageCursor
                            ) else {
                                logger.error("Failed to build cursor values for paginated todo fetch.")
                                break
                            }
                            pageQuery = pageQuery.start(after: cursorValues)
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
                    guard let cursorValues = cursorValues(for: query, cursor: cursor) else {
                        logger.error("Failed to build cursor values for todo fetch.")
                        return TodoPageResponse(items: [], nextCursor: nil)
                    }
                    firestoreQuery = firestoreQuery.start(after: cursorValues)
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

            let todoNumber = searchedTodoNumber(from: trimmedKeyword)
            let filtered = todos.filter { todo in
                if let todoNumber, todo.number == todoNumber {
                    return true
                }

                return todo.title.localizedCaseInsensitiveContains(trimmedKeyword)
                    || todo.content.localizedCaseInsensitiveContains(trimmedKeyword)
                    || todo.tags.contains { $0.localizedCaseInsensitiveContains(trimmedKeyword) }
            }

            return TodoPageResponse(items: filtered, nextCursor: nil)
        } catch {
            logger.error("Failed to fetch todos", error: error)
            record(error, code: .fetchTodos)
            throw error
        }
    }
    // swiftlint:enable function_body_length

    func upsertTodo(request: TodoRequest) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        logger.info("Upserting todo")
        
        do {
            let collection = store.collection(FirestorePath.todos(uid))
            let docRef = collection.document(request.id)
            var data = try encoder.encode(request)
            data.removeValue(forKey: TodoFieldKey.id.rawValue)
            if request.completedAt == nil {
                data[TodoFieldKey.completedAt.rawValue] = NSNull()
            }
            if request.deletedAt == nil {
                data[TodoFieldKey.deletedAt.rawValue] = NSNull()
            }
            if request.dueDate == nil {
                data[TodoFieldKey.dueDate.rawValue] = NSNull()
            }
            try await upsertTodoWithNumberOnCreate(
                data,
                for: docRef,
                counterRef: store.document(
                    FirestorePath.counter(uid, document: .todo)
                )
            )
            
            logger.info("Successfully upserted todo")
        } catch {
            logger.error("Failed to upsert todo", error: error)
            record(error, code: .upsertTodo)
            throw error
        }
    }
    
    func deleteTodo(todoId: String) async throws {
        guard Auth.auth().currentUser?.uid != nil else { throw DataLayerError.notAuthenticated }

        logger.info("Requesting todo deletion")
        
        do {
            let function = functions.httpsCallable(FunctionName.requestTodoDeletion)
            _ = try await function.call(["todoId": todoId])
            
            logger.info("Successfully requested todo deletion")
        } catch {
            logger.error("Failed to request todo deletion", error: error)
            record(error, code: .deleteTodo)
            throw error
        }
    }

    func undoDeleteTodo(todoId: String) async throws {
        guard Auth.auth().currentUser?.uid != nil else { throw DataLayerError.notAuthenticated }

        logger.info("Undoing todo deletion")

        do {
            let function = functions.httpsCallable(FunctionName.undoTodoDeletion)
            _ = try await function.call(["todoId": todoId])

            logger.info("Successfully undone todo deletion")
        } catch {
            logger.error("Failed to undo todo deletion", error: error)
            record(error, code: .undoDeleteTodo)
            throw error
        }
    }

    func fetchTodo(todoId: String) async throws -> TodoResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        logger.info("Fetching todo")

        do {
            let snapshot = try await store.collection(FirestorePath.todos(uid))
                .whereField(FieldPath.documentID(), isEqualTo: todoId)
                .whereField(TodoFieldKey.deletedAt.rawValue, isEqualTo: NSNull())
                .limit(to: 1)
                .getDocuments()
            guard let document = snapshot.documents.first, let todo = makeResponse(from: document) else {
                throw FirestoreError.dataNotFound("Todo")
            }

            logger.info("Successfully fetched todo")
            return todo
        } catch {
            logger.error("Failed to fetch todo", error: error)
            record(error, code: .fetchTodo)
            throw error
        }
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReferenceResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        let uniqueNumbers = Array(Set(numbers)).sorted()
        if uniqueNumbers.isEmpty { return [:] }

        do {
            let collection = store.collection(FirestorePath.todos(uid))
            let snapshots = try await withThrowingTaskGroup(of: [QueryDocumentSnapshot].self) { group in
                for chunk in uniqueNumbers.chunked(maxCount: 10) {
                    group.addTask {
                        let snapshot = try await collection
                            .whereField(TodoFieldKey.number.rawValue, in: chunk)
                            .whereField(TodoFieldKey.deletedAt.rawValue, isEqualTo: NSNull())
                            .getDocuments()
                        return snapshot.documents
                    }
                }

                var documents = [QueryDocumentSnapshot]()
                for try await chunkDocuments in group {
                    documents.append(contentsOf: chunkDocuments)
                }
                return documents
            }

            return snapshots.reduce(into: [Int: TodoReferenceResponse]()) { partialResult, document in
                let data = document.data()
                guard
                    data[TodoFieldKey.deletedAt.rawValue] is NSNull,
                    let response = makeResponse(from: document)
                else {
                    return
                }

                partialResult[response.number] = TodoReferenceResponse(
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
}

private extension TodoServiceImpl {
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

    func upsertTodoWithNumberOnCreate(
        _ data: [String: Any],
        for todoRef: DocumentReference,
        counterRef: DocumentReference
    ) async throws {
        _ = try await store.runTransaction { transaction, errorPointer in
            let todoSnapshot: DocumentSnapshot

            do {
                todoSnapshot = try transaction.getDocument(todoRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            var todoData = data

            if !todoSnapshot.exists {
                let counterSnapshot: DocumentSnapshot

                do {
                    counterSnapshot = try transaction.getDocument(counterRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                let nextNumberValue = counterSnapshot.data()?[CounterFieldKey.nextNumber.rawValue]
                let nextNumber: Int

                if let storedNextNumber = nextNumberValue as? Int {
                    nextNumber = storedNextNumber
                } else if counterSnapshot.exists {
                    errorPointer?.pointee = NSError(
                        domain: "TodoServiceImpl",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Todo counter is invalid."]
                    )
                    return nil
                } else {
                    nextNumber = 1
                }

                todoData[TodoFieldKey.number.rawValue] = nextNumber
                transaction.setData(
                    [
                        CounterFieldKey.nextNumber.rawValue: nextNumber + 1,
                        CounterFieldKey.updatedAt.rawValue: FieldValue.serverTimestamp()
                    ],
                    forDocument: counterRef,
                    merge: true
                )
            }

            transaction.setData(todoData, forDocument: todoRef, merge: true)
            return nil
        }
    }

    func makeQuery(uid: String, query: TodoQuery) -> Query {
        var collection: Query = store.collection(FirestorePath.todos(uid))

        if !query.includesDeleted {
            collection = collection.whereField(TodoFieldKey.deletedAt.rawValue, isEqualTo: NSNull())
        }

        switch query.sortTarget {
        case .dueDate:
            return collection
                .order(by: query.sortTarget.fieldName, descending: query.sortOrder.isDescending)
                .order(by: "updatedAt", descending: true)
                .order(by: FieldPath.documentID())
        case .createdAt, .completedAt, .deletedAt, .updatedAt:
            return collection
                .order(by: query.sortTarget.fieldName, descending: query.sortOrder.isDescending)
                .order(by: FieldPath.documentID())
        }
    }

    func cursorValues(
        for query: TodoQuery,
        cursor: TodoCursorDTO
    ) -> [Any]? {
        let primaryValue: Any = cursor.primarySortDate.map { Timestamp(date: $0) } ?? NSNull()

        switch query.sortTarget {
        case .dueDate:
            guard let sortDate = cursor.secondarySortDate else { return nil }
            return [
                primaryValue,
                Timestamp(date: sortDate),
                cursor.documentID
            ]
        case .createdAt, .completedAt, .deletedAt, .updatedAt:
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
        case .createdAt, .completedAt, .deletedAt, .updatedAt:
            secondarySortDate = nil
        }

        return TodoCursorDTO(
            primarySortDate: primarySortDate,
            secondarySortDate: secondarySortDate,
            documentID: document.documentID
        )
    }

    func makeResponse(from snapshot: QueryDocumentSnapshot) -> TodoResponse? {
        return makeResponse(documentID: snapshot.documentID, data: snapshot.data())
    }

    func makeResponse(from snapshot: DocumentSnapshot) -> TodoResponse? {
        guard let data = snapshot.data() else {
            return nil
        }
        return makeResponse(documentID: snapshot.documentID, data: data)
    }

    func makeResponse(documentID: String, data: [String: Any]) -> TodoResponse? {
        guard
            let number = data[TodoFieldKey.number.rawValue] as? Int,
            let title = data[TodoFieldKey.title.rawValue] as? String,
            let createdAtTimestamp = data[TodoFieldKey.createdAt.rawValue] as? Timestamp,
            let updatedAtTimestamp = data[TodoFieldKey.updatedAt.rawValue] as? Timestamp,
            let category = data[TodoFieldKey.category.rawValue] as? String else {
            return nil
        }

        let completedAt = (data[TodoFieldKey.completedAt.rawValue] as? Timestamp)?.dateValue()
        let deletedAt = (data[TodoFieldKey.deletedAt.rawValue] as? Timestamp)?.dateValue()
        let dueDate = (data[TodoFieldKey.dueDate.rawValue] as? Timestamp)?.dateValue()

        let isPinned = data[TodoFieldKey.isPinned.rawValue] as? Bool ?? false
        let isCompleted = data[TodoFieldKey.isCompleted.rawValue] as? Bool ?? (completedAt != nil)
        let isChecked = data[TodoFieldKey.isChecked.rawValue] as? Bool ?? false
        let content = data[TodoFieldKey.content.rawValue] as? String ?? ""
        let tags = data[TodoFieldKey.tags.rawValue] as? [String] ?? []

        return TodoResponse(
            id: documentID,
            isPinned: isPinned,
            isCompleted: isCompleted,
            isChecked: isChecked,
            number: number,
            title: title,
            content: content,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: dueDate,
            tags: tags,
            category: .raw(category)
        )
    }

    func searchedTodoNumber(from keyword: String) -> Int? {
        guard keyword.hasPrefix("#") else {
            return nil
        }

        let numberText = String(keyword.dropFirst())
        guard !numberText.isEmpty, numberText.allSatisfy(\.isNumber) else {
            return nil
        }

        return Int(numberText)
    }

    enum TodoFieldKey: String {
        case id
        case isPinned
        case isCompleted
        case isChecked
        case number
        case title
        case content
        case createdAt
        case updatedAt
        case completedAt
        case deletedAt
        case dueDate
        case tags
        case category
    }

    enum CounterFieldKey: String {
        case nextNumber
        case updatedAt
    }
}

private extension TodoQuery.SortTarget {
    var fieldName: String {
        switch self {
        case .createdAt:
            return "createdAt"
        case .completedAt:
            return "completedAt"
        case .deletedAt:
            return "deletedAt"
        case .updatedAt:
            return "updatedAt"
        case .dueDate:
            return "dueDate"
        }
    }
}

private extension TodoQuery.SortOrder {
    var isDescending: Bool {
        self == .latest
    }
}

private extension TodoQuery.CompletionFilter {
    var isCompletedValue: Bool? {
        switch self {
        case .all:
            return nil
        case .incomplete:
            return false
        case .completed:
            return true
        }
    }
}
