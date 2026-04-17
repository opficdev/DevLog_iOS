//
//  WidgetSnapshotStore.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation

final class WidgetSnapshotStore {
    private enum Key {
        static let todaySnapshot = "Widget.today.snapshot"
        static let profileHeatmapSnapshot = "Widget.profileHeatmap.snapshot"
    }

    private let store: WidgetSharedDefaultsStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(store: WidgetSharedDefaultsStore = .init()) {
        self.store = store
    }

    func saveTodaySnapshot(_ snapshot: TodayWidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        store.setData(data, forKey: Key.todaySnapshot)
    }

    func loadTodaySnapshot() throws -> TodayWidgetSnapshot? {
        guard let data = store.data(forKey: Key.todaySnapshot) else { return nil }
        return try decoder.decode(TodayWidgetSnapshot.self, from: data)
    }

    func saveProfileHeatmapSnapshot(_ snapshot: ProfileHeatmapWidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        store.setData(data, forKey: Key.profileHeatmapSnapshot)
    }

    func loadProfileHeatmapSnapshot() throws -> ProfileHeatmapWidgetSnapshot? {
        guard let data = store.data(forKey: Key.profileHeatmapSnapshot) else { return nil }
        return try decoder.decode(ProfileHeatmapWidgetSnapshot.self, from: data)
    }
}
