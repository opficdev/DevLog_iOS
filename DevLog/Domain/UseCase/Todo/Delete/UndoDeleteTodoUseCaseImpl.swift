//
//  UndoDeleteTodoUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/15/26.
//

final class UndoDeleteTodoUseCaseImpl: UndoDeleteTodoUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(_ todoId: String) async throws {
        try await repository.undoDeleteTodo(todoId)
    }
}
