//
//  WidgetRepositoryImpl.swift
//  DevLog
//
//  Created by opfic on 4/29/26.
//

import WidgetKit

final class WidgetRepositoryImpl: WidgetRepository {
    private let store: WidgetSnapshotStore

    init(store: WidgetSnapshotStore) {
        self.store = store
    }

    func saveTodaySnapshot(_ snapshot: TodayWidgetSnapshot) throws {
        try store.saveTodaySnapshot(snapshot)
    }

    func saveHeatmapSnapshot(_ snapshot: HeatmapWidgetSnapshot) throws {
        try store.saveHeatmapSnapshot(snapshot)
    }

    func reloadTodayWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.todayTodo)
    }

    func reloadHeatmapWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.heatmap)
    }
}
