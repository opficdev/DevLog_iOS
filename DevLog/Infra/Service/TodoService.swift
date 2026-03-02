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
            "createdAtDescending=\(query.createdAtDescending)",
            query.keyword != nil ? "keywordLength=\(trimmedKeyword.count)" : nil,
            query.kind != nil ? "kind=\(query.kind!.rawValue)" : nil,
            query.isPinned != nil ? "pinned=\(query.isPinned!)" : nil,
            query.createdAtFrom != nil ? "createdAtFrom=\(query.createdAtFrom!)" : nil,
            query.createdAtTo != nil ? "createdAtTo=\(query.createdAtTo!)" : nil,
            "pageSize=\(query.pageSize)",
            query.fetchAllPages ? "fetchAllPages=true" : nil,
            cursor != nil ? "cursor=\(cursor!)" : nil
        ]
        logger.info("Fetching todo page: \(logComponents.compactMap { $0 }.joined(separator: ", "))")

        var firestoreQuery: Query = store
            .collection("users/\(uid)/todoLists/")
            .order(by: "createdAt", descending: query.createdAtDescending)
            .order(by: FieldPath.documentID())

        if let kind = query.kind {
            firestoreQuery = firestoreQuery.whereField("kind", isEqualTo: kind.rawValue)
        }

        if let isPinned = query.isPinned {
            firestoreQuery = firestoreQuery.whereField("isPinned", isEqualTo: isPinned)
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
                        pageQuery = pageQuery.start(after: [
                            Timestamp(date: pageCursor.createdAt),
                            pageCursor.documentID
                        ])
                    }

                    pageQuery = pageQuery.limit(to: query.pageSize)
                    let snapshot = try await pageQuery.getDocuments()
                    allItems.append(contentsOf: snapshot.documents.compactMap { makeResponse(from: $0) })

                    guard snapshot.documents.count == query.pageSize else {
                        break
                    }

                    guard let lastDocument = snapshot.documents.last,
                          let nextCursor = makeCursor(from: lastDocument) else {
                        break
                    }

                    pageCursor = nextCursor
                }

                return TodoPageResponse(items: allItems, nextCursor: nil)
            }

            if let cursor {
                firestoreQuery = firestoreQuery.start(after: [
                    Timestamp(date: cursor.createdAt),
                    cursor.documentID
                ])
            }

            firestoreQuery = firestoreQuery.limit(to: query.pageSize)
            let snapshot = try await firestoreQuery.getDocuments()
            let items = snapshot.documents.compactMap { makeResponse(from: $0) }
            let nextCursor = snapshot.documents.last.flatMap { makeCursor(from: $0) }

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
    func makeCursor(from document: QueryDocumentSnapshot) -> TodoCursorDTO? {
        guard let createdAt = document.data()[TodoFieldKey.createdAt.rawValue] as? Timestamp else {
            return nil
        }

        return TodoCursorDTO(
            createdAt: createdAt.dateValue(),
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
        case dueDate
        case tags
        case kind
    }
}
