//
//  WidgetSnapshotUpdater.swift
//  DevLogData
//
//  Created by opfic on 5/14/26.
//

import Foundation
import DevLogCore

public protocol WidgetSnapshotUpdater: Sendable {
    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot],
        now: Date
    )
    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot],
        displayOptions: TodayDisplayOptions,
        now: Date
    )
    func updateHeatmapSnapshot(
        createdTodos: [WidgetTodoSnapshot],
        completedTodos: [WidgetTodoSnapshot],
        deletedTodos: [WidgetTodoSnapshot],
        quarterStart: Date,
        now: Date
    )
    func clear()
}
