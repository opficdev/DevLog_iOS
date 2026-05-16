//
//  UndoDeleteTodoUseCaseImpl.swift
//  DevLogDomain
//
//  Created by opfic on 3/15/26.
//

public final class UndoDeleteTodoUseCaseImpl: UndoDeleteTodoUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    public func execute(_ todoId: String) async throws {
        try await repository.undoDeleteTodo(todoId)
    }
}
