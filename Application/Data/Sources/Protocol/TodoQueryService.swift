//
//  TodoQueryService.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

import Core

public protocol TodoQueryService {
    func fetchTodos(_ query: TodoQuery, cursor: TodoCursorDTO?) async throws -> TodoPageResponse
    func fetchTodo(todoId: String) async throws -> TodoResponse
    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReferenceResponse]
}
