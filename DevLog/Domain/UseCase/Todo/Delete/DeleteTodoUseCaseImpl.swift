//
//  DeleteTodoUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

final class DeleteTodoUseCaseImpl: DeleteTodoUseCase {
    private let repository: TodoRepository
    
    init(_ repository: TodoRepository) {
        self.repository = repository
    }
    
    func execute(_ todoId: String) async throws {
        try await repository.deleteTodo(todoId)
    }
}
