//
//  FetchTodoUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 2/15/26.
//

final class FetchTodoUseCaseImpl: FetchTodoUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(_ todoID: String) async throws -> Todo {
        try await repository.fetchTodo(todoID)
    }
}
