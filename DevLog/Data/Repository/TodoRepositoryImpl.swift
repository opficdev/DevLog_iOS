//
//  TodoRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation

final class TodoRepositoryImpl: TodoRepository {
    private let authService: AuthService
    private let todoService: TodoService

    init(
        authService: AuthService,
        todoService: TodoService
    ) {
        self.authService = authService
        self.todoService = todoService
    }

    func fetchTodos(_ kind: TodoKind) async throws -> [Todo] {
        guard let uid = authService.uid else { throw AuthError.notAuthenticated }
        let response = try await todoService.fetchTodos(uid: uid, kind: kind)
        return response.map { $0.toDomain() }
    }
    
    func fetchPinnedTodos() async throws -> [Todo] {
        guard let uid = authService.uid else { throw AuthError.notAuthenticated }
        let response = try await todoService.fetchPinnedTodos(uid)
        return response.map { $0.toDomain() }
    }
    
    func upsertTodo(_ todo: Todo) async throws {
        guard let uid = authService.uid else { throw AuthError.notAuthenticated }

        try await todoService.upsertTodo(uid: uid, todo: todo)
    }
    
    func deleteTodo(_ todoID: String) async throws {
        guard let uid = authService.uid else { throw AuthError.notAuthenticated }

        try await todoService.deleteTodo(uid: uid, todoID: todoID)
    }
}
