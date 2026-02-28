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
    private let logger = Logger(category: "TodoService")
    
    func fetchTodos(
        _ query: TodoQuery,
        cursor: TodoCursorDTO?
    ) async throws -> TodoPageResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let trimmedKeyword = query.keyword?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let logMessage = "Fetching todo page: kind=\(String(describing: query.kind)), "
            + "keyword=\(trimmedKeyword), "
            + "pinned=\(String(describing: query.isPinned)), "
            + "cursor=\(String(describing: cursor))"
        logger.info(logMessage)

        var firestoreQuery: Query = store
            .collection("users/\(uid)/todoLists/")
            .order(by: "createdAt", descending: true)
            .order(by: FieldPath.documentID())

        if let kind = query.kind {
            firestoreQuery = firestoreQuery.whereField("kind", isEqualTo: kind.rawValue)
        }

        if let isPinned = query.isPinned {
            firestoreQuery = firestoreQuery.whereField("isPinned", isEqualTo: isPinned)
        }

        if trimmedKeyword.isEmpty {
            if let cursor {
                firestoreQuery = firestoreQuery.start(after: [
                    Timestamp(date: cursor.createdAt),
                    cursor.documentID
                ])
            }

            let snapshot = try await firestoreQuery
                .limit(to: query.pageSize)
                .getDocuments()

            let items = snapshot.documents.compactMap { makeResponse(from: $0) }

            let nextCursor: TodoCursorDTO? = snapshot.documents.last.flatMap { document in
                guard let createdAt = document.data()["createdAt"] as? Timestamp else {
                    return nil
                }

                return TodoCursorDTO(
                    createdAt: createdAt.dateValue(),
                    documentID: document.documentID
                )
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
            try await docRef.setData(request.toDictionary(), merge: true)
            
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
            let isPinned = data["isPinned"] as? Bool,
            let isCompleted = data["isCompleted"] as? Bool,
            let isChecked = data["isChecked"] as? Bool,
            let title = data["title"] as? String,
            let content = data["content"] as? String,
            let createdAtTimestamp = data["createdAt"] as? Timestamp,
            let updatedAtTimestamp = data["updatedAt"] as? Timestamp,
            let tags = data["tags"] as? [String],
            let kind = data["kind"] as? String else {
            return nil
        }

        let dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
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
}
