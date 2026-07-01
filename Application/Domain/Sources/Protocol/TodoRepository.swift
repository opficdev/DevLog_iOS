//
//  TodoRepository.swift
//  Domain
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation
import Core

public protocol TodoRepository {
    func fetchTodos(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage
    func fetchTodo(_ todoId: String) async throws -> Todo
    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReference]
    func upsertTodo(_ todo: Todo) async throws
    func upsertTodo(_ todoDraft: TodoDraft) async throws
    func deleteTodo(_ todoId: String) async throws
    func undoDeleteTodo(_ todoId: String) async throws
}
