//
//  WidgetTodoSnapshotRepository.swift
//  DevLogData
//
//  Created by opfic on 6/8/26.
//

import Foundation
import DevLogCore

public protocol WidgetTodoSnapshotRepository {
    func fetchTodayTodos(
        dueDateFilter: TodoQuery.DueDateFilter,
        sortTarget: TodoQuery.SortTarget,
        sortOrder: TodoQuery.SortOrder,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot]

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot]
}
