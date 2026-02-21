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
    
    func fetchPinnedTodos() async throws -> [TodoResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Fetching pinned todos for user: \(uid)")
        
        do {
            let collection = store.collection("users/\(uid)/todoLists/")

            let query = collection.whereField(("isPinned"), isEqualTo: true)
                .order(by: "createdAt", descending: true)
            
            let snapshot = try await query.getDocuments()
            let todos = snapshot.documents.compactMap { TodoResponse(from: $0) }
            
            logger.info("Successfully fetched \(todos.count) pinned todos")
            return todos
        } catch {
            logger.error("Failed to fetch pinned todos", error: error)
            throw error
        }
    }

    func fetchTodos(kind: TodoKind) async throws -> [TodoResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Fetching todos of kind: \(kind.rawValue) for user: \(uid)")
        
        do {
            let collection = store.collection("users/\(uid)/todoLists/")

            let query = collection.whereField("kind", isEqualTo: kind.rawValue)
                .order(by: "createdAt", descending: true)
            
            let snapshot = try await query.getDocuments()
            let todos = snapshot.documents.compactMap { TodoResponse(from: $0) }
            
            logger.info("Successfully fetched \(todos.count) todos")
            return todos
        } catch {
            logger.error("Failed to fetch todos", error: error)
            throw error
        }
    }

    func fetchTodos(_ keyword: String) async throws -> [TodoResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        logger.info("Fetching todos by keyword: \(trimmedKeyword) for user: \(uid)")

        do {
            let collection = store.collection("users/\(uid)/todoLists/")
            let query = collection.order(by: "createdAt", descending: true)

            let snapshot = try await query.getDocuments()
            let todos = snapshot.documents.compactMap { TodoResponse(from: $0) }

            guard !trimmedKeyword.isEmpty else {
                logger.info("Successfully fetched \(todos.count) todos without keyword")
                return todos
            }

            let filtered = todos.filter { todo in
                todo.title.localizedCaseInsensitiveContains(trimmedKeyword)
                    || todo.content.localizedCaseInsensitiveContains(trimmedKeyword)
                    || todo.tags.contains { $0.localizedCaseInsensitiveContains(trimmedKeyword) }
            }

            logger.info("Successfully fetched \(filtered.count) todos with keyword")
            return filtered
        } catch {
            logger.error("Failed to fetch todos with keyword", error: error)
            throw error
        }
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
            guard snapshot.exists, let todo = TodoResponse(from: snapshot) else {
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
