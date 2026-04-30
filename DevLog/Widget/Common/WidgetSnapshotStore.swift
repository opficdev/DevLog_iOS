//
//  WidgetSnapshotStore.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation

final class WidgetSnapshotStore {
    private let store: WidgetSharedDefaultsStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(store: WidgetSharedDefaultsStore = .init()) {
        self.store = store
    }

    func saveTodaySnapshot(_ snapshot: TodayWidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        store.setData(data, forKey: WidgetSnapshotKey.today)
    }

    func loadTodaySnapshot() throws -> TodayWidgetSnapshot? {
        guard let data = store.data(forKey: WidgetSnapshotKey.today) else { return nil }
        return try decoder.decode(TodayWidgetSnapshot.self, from: data)
    }

    func saveHeatmapSnapshot(_ snapshot: HeatmapWidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        store.setData(data, forKey: WidgetSnapshotKey.heatmap)
    }

    func loadHeatmapSnapshot() throws -> HeatmapWidgetSnapshot? {
        guard let data = store.data(forKey: WidgetSnapshotKey.heatmap) else { return nil }
        return try decoder.decode(HeatmapWidgetSnapshot.self, from: data)
    }
}
