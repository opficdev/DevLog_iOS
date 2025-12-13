//
//  FetchPinnedTodosUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

final class FetchPinnedTodosUseCaseImpl: FetchPinnedTodosUseCase {
    let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Todo] {
        try await repository.fetchPinnedTodos()
    }
}

