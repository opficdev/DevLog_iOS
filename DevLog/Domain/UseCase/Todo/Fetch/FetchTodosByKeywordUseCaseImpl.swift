//
//  FetchTodosByKeywordUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 2/21/26.
//

final class FetchTodosByKeywordUseCaseImpl: FetchTodosByKeywordUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(_ keyword: String) async throws -> [Todo] {
        try await repository.fetchTodos(keyword)
    }
}
