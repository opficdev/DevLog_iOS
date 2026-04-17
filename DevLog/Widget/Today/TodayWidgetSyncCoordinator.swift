//
//  TodayWidgetSyncCoordinator.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation
import WidgetKit

final class TodayWidgetSyncCoordinator {
    private let factory: TodayWidgetSnapshotFactory
    private let store: WidgetSnapshotStore

    init(
        factory: TodayWidgetSnapshotFactory = .init(),
        store: WidgetSnapshotStore = .init()
    ) {
        self.factory = factory
        self.store = store
    }

    func sync(
        todos: [TodayTodoItem],
        displayOptions: TodayDisplayOptions,
        now: Date = Date()
    ) {
        let todayWidgetSnapshot = factory.makeSnapshot(
            todos: todos,
            displayOptions: displayOptions,
            now: now
        )

        do {
            try store.saveTodaySnapshot(todayWidgetSnapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: "TodayTodoWidget")
        } catch {
            return
        }
    }
}
