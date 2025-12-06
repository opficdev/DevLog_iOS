//
//  FetchPinnedTodoListUseCasing.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

protocol FetchPinnedTodosUseCasing {
    var repository: TodoRepository { get }
    func execute() async throws -> [Todo]
}
