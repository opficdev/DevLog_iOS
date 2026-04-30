//
//  WidgetSnapshotPreferenceStore.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Foundation

final class WidgetSnapshotPreferenceStore {
    private enum Key {
        static let heatmapActivityTypes = "Profile.heatmap.activityTypes"
        static let todayDueDateVisibility = "Today.dueDateVisibility"
        static let todayFocusVisibility = "Today.focusVisibility"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func heatmapActivityTypes() -> [String] {
        userDefaults.stringArray(forKey: Key.heatmapActivityTypes) ?? []
    }

    func setHeatmapActivityTypes(_ activityTypes: [String]) {
        userDefaults.set(activityTypes, forKey: Key.heatmapActivityTypes)
    }

    func selectedActivityKinds() -> Set<ActivityKind> {
        let selectedActivityKinds = Set(
            heatmapActivityTypes().compactMap(ActivityKind.init(rawValue:))
        )
        let selectableActivityKinds: [ActivityKind] = [.created, .completed, .deleted]
        let normalizedActivityKinds = Set(
            selectableActivityKinds.filter { selectedActivityKinds.contains($0) }
        )

        return normalizedActivityKinds.isEmpty ? Set(selectableActivityKinds) : normalizedActivityKinds
    }

    func todayDisplayOptions() -> TodayDisplayOptions {
        let dueDateVisibilityRawValue = userDefaults.string(forKey: Key.todayDueDateVisibility)
        let focusVisibilityRawValue = userDefaults.string(forKey: Key.todayFocusVisibility)

        return TodayDisplayOptions(
            dueDateVisibility: TodayDisplayOptions.DueDateVisibility(
                rawValue: dueDateVisibilityRawValue ?? ""
            ) ?? .all,
            focusVisibility: TodayDisplayOptions.FocusVisibility(
                rawValue: focusVisibilityRawValue ?? ""
            ) ?? .all
        )
    }

    func setTodayDisplayOptions(_ options: TodayDisplayOptions) {
        userDefaults.set(options.dueDateVisibility.rawValue, forKey: Key.todayDueDateVisibility)
        userDefaults.set(options.focusVisibility.rawValue, forKey: Key.todayFocusVisibility)
    }
}
