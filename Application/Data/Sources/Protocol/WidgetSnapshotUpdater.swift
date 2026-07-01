//
//  WidgetSnapshotUpdater.swift
//  Data
//
//  Created by opfic on 5/14/26.
//

import Foundation
import Core

public protocol WidgetSnapshotUpdater {
    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot]?,
        displayOptions: TodayDisplayOptions?,
        now: Date
    )

    func updateHeatmapSnapshot(
        createdTodos: [WidgetTodoSnapshot]?,
        completedTodos: [WidgetTodoSnapshot]?,
        deletedTodos: [WidgetTodoSnapshot]?,
        quarterStart: Date?,
        now: Date
    )

    func upsertTodoSnapshot(
        _ todo: WidgetTodoSnapshot,
        now: Date
    )

    func deleteTodoSnapshot(
        todoId: String,
        deletedAt: Date,
        now: Date
    )

    func restoreTodoSnapshot(
        todoId: String,
        now: Date
    )

    func clear()
}

public extension WidgetSnapshotUpdater {
    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot]? = nil,
        displayOptions: TodayDisplayOptions? = nil,
        now: Date
    ) {
        updateTodaySnapshot(
            todos: todos,
            displayOptions: displayOptions,
            now: now
        )
    }

    func updateHeatmapSnapshot(
        createdTodos: [WidgetTodoSnapshot]? = nil,
        completedTodos: [WidgetTodoSnapshot]? = nil,
        deletedTodos: [WidgetTodoSnapshot]? = nil,
        quarterStart: Date? = nil,
        now: Date
    ) {
        updateHeatmapSnapshot(
            createdTodos: createdTodos,
            completedTodos: completedTodos,
            deletedTodos: deletedTodos,
            quarterStart: quarterStart,
            now: now
        )
    }
}
