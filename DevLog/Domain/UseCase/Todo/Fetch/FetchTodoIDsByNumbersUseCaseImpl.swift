//
//  FetchTodoIDsByNumbersUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/25/26.
//

final class FetchTodoIDsByNumbersUseCaseImpl: FetchTodoIDsByNumbersUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(_ numbers: [Int]) async throws -> [Int: String] {
        try await repository.fetchTodoIDs(numbers)
    }
}
