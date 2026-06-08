//
//  WidgetTodoSnapshotRepositoryImpl.swift
//  DevLogData
//
//  Created by opfic on 6/8/26.
//

import Foundation
import DevLogCore
import DevLogDomain

final class WidgetTodoSnapshotRepositoryImpl: WidgetTodoSnapshotRepository {
    private let repository: TodoRepository

    init(repository: TodoRepository) {
        self.repository = repository
    }

    func fetchTodayTodos(
        dueDateFilter: TodoQuery.DueDateFilter,
        sortTarget: TodoQuery.SortTarget,
        sortOrder: TodoQuery.SortOrder,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot] {
        let todoPage = try await repository.fetchTodos(
            TodoQuery(
                completionFilter: .incomplete,
                dueDateFilter: dueDateFilter,
                sortTarget: sortTarget,
                sortOrder: sortOrder,
                pageSize: pageSize,
                fetchAllPages: true
            ),
            cursor: nil
        )

        return todoPage.items.map(WidgetTodoSnapshot.fromDomain)
    }

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot] {
        let todoPage = try await repository.fetchTodos(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: sortTarget,
                pageSize: pageSize,
                fetchAllPages: true
            ),
            cursor: nil
        )

        return todoPage.items.map(WidgetTodoSnapshot.fromDomain)
    }
}
