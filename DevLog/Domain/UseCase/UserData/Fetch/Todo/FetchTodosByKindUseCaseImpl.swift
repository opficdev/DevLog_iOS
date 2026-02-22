//
//  FetchTodosByKindUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/1/26.
//

final class FetchTodosByKindUseCaseImpl: FetchTodosByKindUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(_ kind: TodoKind, cursor: TodoCursor?) async throws -> TodoPage {
        let query = TodoQuery(kind: kind)
        return try await repository.fetchTodos(query, cursor: cursor)
    }
}
