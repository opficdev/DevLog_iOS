//
//  FetchTodosByDateRangeUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/1/26.
//

import Foundation

final class FetchTodosByDateRangeUseCaseImpl: FetchTodosByDateRangeUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute(from startDate: Date, to endDate: Date) async throws -> [Todo] {
        let query = TodoQuery(
            createdAtFrom: startDate,
            createdAtTo: endDate,
            pageSize: nil
        )
        let page = try await repository.fetchTodos(query, cursor: nil)
        return page.items
    }
}
