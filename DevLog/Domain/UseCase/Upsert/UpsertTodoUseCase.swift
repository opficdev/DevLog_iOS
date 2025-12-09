//
//  UpsertTodoUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 12/8/25.
//

final class UpsertTodoUseCase: UpsertTodoUseCasing {
    let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(_ todo: Todo) async throws {
        try await repository.upsertTodo(todo)
    }
}
