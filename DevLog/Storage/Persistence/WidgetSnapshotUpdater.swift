//
//  WidgetSnapshotUpdater.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Foundation
import WidgetKit

final class WidgetSnapshotUpdater {
    private let snapshotStore: WidgetSnapshotStore
    private let preferenceStore: WidgetSnapshotPreferenceStore
    private let todayFactory: TodayWidgetSnapshotFactory
    private let heatmapFactory: HeatmapWidgetSnapshotFactory
    private let calendar: Calendar
    private let logger = Logger(category: "WidgetSnapshotUpdater")

    init(
        snapshotStore: WidgetSnapshotStore,
        preferenceStore: WidgetSnapshotPreferenceStore,
        todayFactory: TodayWidgetSnapshotFactory = .init(),
        heatmapFactory: HeatmapWidgetSnapshotFactory = .init(),
        calendar: Calendar = .current
    ) {
        self.snapshotStore = snapshotStore
        self.preferenceStore = preferenceStore
        self.todayFactory = todayFactory
        self.heatmapFactory = heatmapFactory
        self.calendar = calendar
    }

    func updateTodaySnapshot(
        todos: [TodayTodoItem],
        now: Date = Date()
    ) {
        updateTodaySnapshot(
            todos: todos,
            displayOptions: preferenceStore.todayDisplayOptions(),
            now: now
        )
    }

    func updateTodaySnapshot(
        todos: [TodayTodoItem],
        displayOptions: TodayDisplayOptions,
        now: Date = Date()
    ) {
        let todayWidgetSnapshot = todayFactory.makeSnapshot(
            todos: todos,
            displayOptions: displayOptions,
            now: now
        )

        do {
            try snapshotStore.saveTodaySnapshot(todayWidgetSnapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.todayTodo)
        } catch {
            logger.error(
                "Failed to update today widget snapshot.",
                error: error
            )
        }
    }

    func updateHeatmapSnapshot(
        createdTodos: [Todo],
        completedTodos: [Todo],
        deletedTodos: [Todo],
        quarterStart: Date,
        now: Date = Date()
    ) {
        updateHeatmapSnapshot(
            createdTodos: createdTodos,
            completedTodos: completedTodos,
            deletedTodos: deletedTodos,
            selectedActivityKinds: preferenceStore.selectedActivityKinds(),
            quarterStart: quarterStart,
            now: now
        )
    }

    func updateHeatmapSnapshot(
        createdTodos: [Todo],
        completedTodos: [Todo],
        deletedTodos: [Todo],
        selectedActivityKinds: Set<ActivityKind>,
        quarterStart: Date,
        now: Date = Date()
    ) {
        let heatmapWidgetSnapshot = heatmapFactory.makeSnapshot(
            createdTodos: createdTodos,
            completedTodos: completedTodos,
            deletedTodos: deletedTodos,
            selectedActivityKinds: selectedActivityKinds,
            quarterStart: quarterStart,
            now: now
        )

        do {
            try snapshotStore.saveHeatmapSnapshot(heatmapWidgetSnapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.heatmap)
        } catch {
            logger.error(
                "Failed to update heatmap widget snapshot.",
                error: error
            )
        }
    }

    func startOfQuarter(for date: Date) -> Date {
        let month = calendar.component(.month, from: date)
        let startMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = startMonth
        components.day = 1
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }
}
