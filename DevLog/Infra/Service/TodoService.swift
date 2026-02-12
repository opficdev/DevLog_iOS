//
//  TodoService.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import FirebaseFirestore

final class TodoService {
    private let store = Firestore.firestore()
    private let logger = Logger(category: "TodoService")
    
    func fetchPinnedTodos(_ uid: String) async throws -> [TodoResponse] {
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

    func fetchTodos(uid: String, kind: TodoKind) async throws -> [TodoResponse] {
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
    
    func upsertTodo(uid: String, request: TodoRequest) async throws {
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
    
    func deleteTodo(uid: String, todoID: String) async throws {
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
}
