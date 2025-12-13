//
//  FetchPinnedTodosUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

protocol FetchPinnedTodosUseCase {
    var repository: TodoRepository { get }
    func execute() async throws -> [Todo]
}
