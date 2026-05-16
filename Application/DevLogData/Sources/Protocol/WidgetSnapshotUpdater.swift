//
//  WidgetSnapshotUpdater.swift
//  DevLogData
//
//  Created by opfic on 5/14/26.
//

import Foundation
import DevLogDomain

public protocol WidgetSnapshotUpdater {
    func updateTodaySnapshot(
        todos: [Todo],
        now: Date
    )
    func updateTodaySnapshot(
        todos: [Todo],
        displayOptions: TodayDisplayOptions,
        now: Date
    )
    func updateHeatmapSnapshot(
        createdTodos: [Todo],
        completedTodos: [Todo],
        deletedTodos: [Todo],
        quarterStart: Date,
        now: Date
    )
    func clear()
}
