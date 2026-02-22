//
//  FetchPinnedTodosUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

final class FetchPinnedTodosUseCaseImpl: FetchPinnedTodosUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Todo] {
        let query = TodoQuery(isPinned: true)
        let page = try await repository.fetchTodos(query, cursor: nil)
        return page.items
    }
}
