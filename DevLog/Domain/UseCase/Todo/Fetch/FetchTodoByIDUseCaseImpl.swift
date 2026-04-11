//
//  FetchTodoUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 2/15/26.
//

final class FetchTodoByIdUseCaseImpl: FetchTodoByIdUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(_ todoId: String) async throws -> Todo {
        try await repository.fetchTodo(todoId)
    }
}
