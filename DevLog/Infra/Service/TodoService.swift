//
//  TodoService.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import Foundation
import Combine
import FirebaseFirestore

class TodoService {
    private let store = Firestore.firestore()
    
    func requestPinnedTodoList(uid: String) async throws -> [TodoResponse] {
        let collection = store.collection("users/\(uid)/todoLists/")

        let query = collection.whereField(("isPinned"), isEqualTo: true)
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { TodoResponse(from: $0) }
    }

    func requestTodoList(kind: TodoKind, uid: String) async throws -> [TodoResponse] {
        let collection = store.collection("users/\(uid)/todoLists/")

        let query = collection.whereField("kind", isEqualTo: kind.rawValue)
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { TodoResponse(from: $0) }
    }
    
    func upsertTodo(todo: Todo, uid: String) async throws {
        let collection = store.collection("users/\(uid)/todoLists/")

        let docRef = collection.document(todo.id)
        
        try await docRef.setData(todo.toDictionary(), merge: true)
    }
    
    func deleteTodo(todo: Todo, uid: String) async throws {
        let collection = store.collection("users/\(uid)/todoLists/")

        let docRef = collection.document(todo.id)
        
        try await docRef.delete()
    }
}
