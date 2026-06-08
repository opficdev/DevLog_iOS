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
    private let todoService: TodoService

    init(todoService: TodoService) {
        self.todoService = todoService
    }

    func fetchTodayTodos(
        dueDateFilter: TodoQuery.DueDateFilter,
        sortTarget: TodoQuery.SortTarget,
        sortOrder: TodoQuery.SortOrder,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot] {
        let query = TodoQuery(
            completionFilter: .incomplete,
            dueDateFilter: dueDateFilter,
            sortTarget: sortTarget,
            sortOrder: sortOrder,
            pageSize: pageSize,
            fetchAllPages: true
        )

        do {
            let todoPage = try await todoService.fetchTodos(query, cursor: nil)
            return todoPage.items.map(WidgetTodoSnapshot.fromResponse)
        } catch {
            throw error.toDomain()
        }
    }

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot] {
        let query = TodoQuery(
            sortDateFrom: quarterStart,
            sortDateTo: nextQuarterStart,
            includesDeleted: true,
            sortTarget: sortTarget,
            pageSize: pageSize,
            fetchAllPages: true
        )

        do {
            let todoPage = try await todoService.fetchTodos(query, cursor: nil)
            return todoPage.items.map(WidgetTodoSnapshot.fromResponse)
        } catch {
            throw error.toDomain()
        }
    }
}

private extension WidgetTodoSnapshot {
    static func fromResponse(_ response: TodoResponse) -> Self {
        WidgetTodoSnapshot(
            id: response.id,
            number: response.number,
            title: response.title,
            isPinned: response.isPinned,
            createdAt: response.createdAt,
            completedAt: response.completedAt,
            deletedAt: response.deletedAt,
            dueDate: response.dueDate
        )
    }
}
