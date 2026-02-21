//
//  TodoRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation

final class TodoRepositoryImpl: TodoRepository {
    private let todoService: TodoService

    init(todoService: TodoService) {
        self.todoService = todoService
    }

    func fetchTodos(_ kind: TodoKind) async throws -> [Todo] {
        let response = try await todoService.fetchTodos(kind: kind)
        return try response.map { try $0.toDomain() }
    }

    func fetchTodos(_ keyword: String) async throws -> [Todo] {
        let response = try await todoService.fetchTodos(keyword)
        return try response.map { try $0.toDomain() }
    }

    func fetchPinnedTodos() async throws -> [Todo] {
        let response = try await todoService.fetchPinnedTodos()
        return try response.map { try $0.toDomain() }
    }

    func fetchTodo(_ todoID: String) async throws -> Todo {
        let response = try await todoService.fetchTodo(todoID: todoID)
        return try response.toDomain()
    }
    
    func upsertTodo(_ todo: Todo) async throws {
        let request = TodoRequest.fromDomain(todo)
        try await todoService.upsertTodo(request: request)
    }
    
    func deleteTodo(_ todoID: String) async throws {
        try await todoService.deleteTodo(todoID: todoID)
    }
}
