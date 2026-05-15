//
//  WidgetSnapshotStore.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation
import DevLogDomain
import DevLogDataCommon
import DevLogDataProtocol
import DevLogWidgetShared

public final class WidgetSnapshotStore {
    private let store: WidgetSharedDefaultsStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {
        self.store = WidgetSharedDefaultsStore()
    }

    init(store: WidgetSharedDefaultsStore) {
        self.store = store
    }

    public func saveTodaySnapshot(_ snapshot: TodayWidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        store.setData(data, forKey: WidgetSnapshotKey.today)
    }

    public func loadTodaySnapshot() throws -> TodayWidgetSnapshot? {
        guard let data = store.data(forKey: WidgetSnapshotKey.today) else { return nil }
        return try decoder.decode(TodayWidgetSnapshot.self, from: data)
    }

    public func saveHeatmapSnapshot(_ snapshot: HeatmapWidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        store.setData(data, forKey: WidgetSnapshotKey.heatmap)
    }

    public func loadHeatmapSnapshot() throws -> HeatmapWidgetSnapshot? {
        guard let data = store.data(forKey: WidgetSnapshotKey.heatmap) else { return nil }
        return try decoder.decode(HeatmapWidgetSnapshot.self, from: data)
    }

    public func clearSnapshots() {
        WidgetSnapshotKey.snapshots.forEach {
            store.removeObject(forKey: $0)
        }
    }
}
