//
//  WidgetSyncEvent.swift
//  DevLog
//
//  Created by opfic on 4/29/26.
//

import Foundation

enum WidgetSyncEvent {
    case todaySnapshotChanged(
        todos: [TodayTodoItem],
        displayOptions: TodayDisplayOptions
    )
    case heatmapSnapshotChanged(
        selectedActivityKinds: Set<ActivityKind>
    )
}
