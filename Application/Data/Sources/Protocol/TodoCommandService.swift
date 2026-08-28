//
//  TodoCommandService.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

import Core

public protocol TodoCommandService {
    func upsertTodo(request: TodoRequest) async throws
    func deleteTodo(todoId: String) async throws
    func undoDeleteTodo(todoId: String) async throws
}
