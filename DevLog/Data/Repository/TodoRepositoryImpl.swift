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

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        let responseCursor = cursor.map { TodoCursorDTO.fromDomain($0) }
        let response = try await todoService.fetchTodos(query, cursor: responseCursor)
        return try response.toDomain()
    }

    func fetchTodo(_ todoId: String) async throws -> Todo {
        let response = try await todoService.fetchTodo(todoId: todoId)
        return try response.toDomain()
    }
    
    func upsertTodo(_ todo: Todo) async throws {
        let request = TodoRequest.fromDomain(todo)
        try await todoService.upsertTodo(request: request)
    }
    
    func deleteTodo(_ todoId: String) async throws {
        try await todoService.deleteTodo(todoId: todoId)
    }
}
