//
//  TodoService.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

final class TodoService {
    private enum FunctionName: String {
        case requestTodoDeletion
        case undoTodoDeletion
    }

    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let encoder = Firestore.Encoder()
    private let logger = Logger(category: "TodoService")
    
    // swiftlint:disable function_body_length
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
            query.category != nil ? "category=\(query.category!.rawValue)" : nil,
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

        var firestoreQuery = makeQuery(uid: uid, query: query)

        if let category = query.category {
            firestoreQuery = firestoreQuery.whereField(
                TodoFieldKey.category.rawValue,
                isEqualTo: category.rawValue
            )
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
                        guard let cursorValues = cursorValues(for: query, cursor: pageCursor) else {
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

        let filtered = todos.filter { todo in
            todo.title.localizedCaseInsensitiveContains(trimmedKeyword)
                || todo.content.localizedCaseInsensitiveContains(trimmedKeyword)
                || todo.tags.contains { $0.localizedCaseInsensitiveContains(trimmedKeyword) }
        }

        return TodoPageResponse(items: filtered, nextCursor: nil)
    }
    // swiftlint:enable function_body_length

    func upsertTodo(request: TodoRequest) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Upserting todo")
        
        do {
            let collection = store.collection(FirestorePath.todos(uid))
            let docRef = collection.document(request.id)
            var data = try encoder.encode(request)
            data.removeValue(forKey: TodoFieldKey.id.rawValue)
            if let number = request.number {
                data[TodoFieldKey.number.rawValue] = number
            }
            if request.completedAt == nil {
                data[TodoFieldKey.completedAt.rawValue] = NSNull()
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
            throw error
        }
    }
    
    func deleteTodo(todoId: String) async throws {
        guard Auth.auth().currentUser?.uid != nil else { throw AuthError.notAuthenticated }

        logger.info("Requesting todo deletion")
        
        do {
            let function = functions.httpsCallable(FunctionName.requestTodoDeletion)
            _ = try await function.call(["todoId": todoId])
            
            logger.info("Successfully requested todo deletion")
        } catch {
            logger.error("Failed to request todo deletion", error: error)
            throw error
        }
    }

    func undoDeleteTodo(todoId: String) async throws {
        guard Auth.auth().currentUser?.uid != nil else { throw AuthError.notAuthenticated }

        logger.info("Undoing todo deletion")

        do {
            let function = functions.httpsCallable(FunctionName.undoTodoDeletion)
            _ = try await function.call(["todoId": todoId])

            logger.info("Successfully undone todo deletion")
        } catch {
            logger.error("Failed to undo todo deletion", error: error)
            throw error
        }
    }

    func fetchTodo(todoId: String) async throws -> TodoResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Fetching todo")

        do {
            let docRef = store.document(FirestorePath.todo(uid, todoId: todoId))
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

    func fetchReferenceItems(_ numbers: [Int]) async throws -> [Int: TodoReferenceItem] {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let uniqueNumbers = Array(Set(numbers)).sorted()
        if uniqueNumbers.isEmpty { return [:] }

        let collection = store.collection(FirestorePath.todos(uid))
        let snapshots = try await withThrowingTaskGroup(of: [QueryDocumentSnapshot].self) { group in
            for chunk in uniqueNumbers.chunked(maxCount: 10) {
                group.addTask {
                    let snapshot = try await collection
                        .whereField(TodoFieldKey.number.rawValue, in: chunk)
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

        return snapshots.reduce(into: [Int: TodoReferenceItem]()) { partialResult, document in
            let data = document.data()
            guard
                !(data[TodoFieldKey.deletingAt.rawValue] is Timestamp),
                let response = makeResponse(from: document),
                let category = TodoCategory(rawValue: response.category)
            else {
                return
            }

            partialResult[response.number] = TodoReferenceItem(
                id: response.id,
                title: response.title,
                category: category
            )
        }
    }
}

private extension TodoService {
    func upsertTodoWithNumberOnCreate(
        _ data: [String: Any],
        for todoRef: DocumentReference,
        counterRef: DocumentReference
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.runTransaction({ transaction, errorPointer in
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
                            domain: "TodoService",
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
            }) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }

    func makeQuery(uid: String, query: TodoQuery) -> Query {
        let collection = store.collection(FirestorePath.todos(uid))

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
        if snapshot.data()[TodoFieldKey.deletingAt.rawValue] is Timestamp {
            return nil
        }
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
            let isPinned = data[TodoFieldKey.isPinned.rawValue] as? Bool,
            let isCompleted = data[TodoFieldKey.isCompleted.rawValue] as? Bool,
            let isChecked = data[TodoFieldKey.isChecked.rawValue] as? Bool,
            let number = data[TodoFieldKey.number.rawValue] as? Int,
            let title = data[TodoFieldKey.title.rawValue] as? String,
            let content = data[TodoFieldKey.content.rawValue] as? String,
            let createdAtTimestamp = data[TodoFieldKey.createdAt.rawValue] as? Timestamp,
            let updatedAtTimestamp = data[TodoFieldKey.updatedAt.rawValue] as? Timestamp,
            let tags = data[TodoFieldKey.tags.rawValue] as? [String],
            let category = data[TodoFieldKey.category.rawValue] as? String else {
            return nil
        }

        let completedAt = (data[TodoFieldKey.completedAt.rawValue] as? Timestamp)?.dateValue()
        let dueDate = (data[TodoFieldKey.dueDate.rawValue] as? Timestamp)?.dateValue()
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
            dueDate: dueDate,
            tags: tags,
            category: category
        )
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
        case dueDate
        case tags
        case category
        case deletingAt // 삭제 요청은 되었지만, 5초 유예 후 최종 삭제되기 전 상태
    }

    enum CounterFieldKey: String {
        case nextNumber
        case updatedAt
    }
}
