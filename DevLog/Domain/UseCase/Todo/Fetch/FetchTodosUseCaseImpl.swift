//
//  FetchTodosUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/3/26.
//

final class FetchTodosUseCaseImpl: FetchTodosUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        try await repository.fetchTodos(query, cursor: cursor)
    }
}
