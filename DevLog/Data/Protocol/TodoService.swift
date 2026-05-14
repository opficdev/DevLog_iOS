//
//  TodoService.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation
import DevLogDomain
import DevLogDataDTO

public protocol TodoService {
    func fetchTodos(_ query: TodoQuery, cursor: TodoCursorDTO?) async throws -> TodoPageResponse
    func upsertTodo(request: TodoRequest) async throws
    func deleteTodo(todoId: String) async throws
    func undoDeleteTodo(todoId: String) async throws
    func fetchTodo(todoId: String) async throws -> TodoResponse
    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReferenceResponse]
}
