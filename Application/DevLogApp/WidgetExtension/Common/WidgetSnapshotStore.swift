//
//  WidgetSnapshotStore.swift
//  DevLogWidget
//
//  Created by opfic on 4/17/26.
//

import Foundation
import DevLogWidgetShared

final class WidgetSnapshotStore {
    private let store: WidgetSharedDefaultsStore
    private let decoder = JSONDecoder()

    init(store: WidgetSharedDefaultsStore = .init()) {
        self.store = store
    }

    func loadTodaySnapshot() throws -> TodayWidgetSnapshot? {
        guard let data = store.data(forKey: WidgetSnapshotKey.today) else { return nil }
        return try decoder.decode(TodayWidgetSnapshot.self, from: data)
    }

    func loadHeatmapSnapshot() throws -> HeatmapWidgetSnapshot? {
        guard let data = store.data(forKey: WidgetSnapshotKey.heatmap) else { return nil }
        return try decoder.decode(HeatmapWidgetSnapshot.self, from: data)
    }
}
