//
//  TodoRepository.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation

protocol TodoRepository {
    func fetchTodos(_ kind: TodoKind) async throws -> [Todo]
    func fetchPinnedTodos() async throws -> [Todo]
    func upsertTodo(_ todo: Todo) async throws
    func deleteTodo(_ todoID: String) async throws
}
