//
//  UpsertTodoUseCaseImpl.swift
//  DevLogDomain
//
//  Created by 최윤진 on 12/8/25.
//

public final class UpsertTodoUseCaseImpl: UpsertTodoUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    public func execute(_ todo: Todo) async throws {
        try await repository.upsertTodo(todo)
    }
}
