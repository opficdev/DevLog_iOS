//
//  DeleteTodoUseCaseImpl.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/12/26.
//

public final class DeleteTodoUseCaseImpl: DeleteTodoUseCase {
    private let repository: TodoRepository
    
    init(_ repository: TodoRepository) {
        self.repository = repository
    }
    
    public func execute(_ todoId: String) async throws {
        try await repository.deleteTodo(todoId)
    }
}
