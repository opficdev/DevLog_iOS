//
//  WidgetSnapshotPreferenceStoreImpl.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Foundation
import DevLogDomain
import DevLogDataCommon
import DevLogDataProtocol
import DevLogWidgetCore
import DevLogWidgetShared

final class WidgetSnapshotPreferenceStoreImpl: WidgetSnapshotPreferenceStore {
    private enum Key: String, CaseIterable {
        case heatmapActivityTypes = "Profile.heatmap.activityTypes"
        case todayDueDateVisibility = "Today.dueDateVisibility"
        case todayFocusVisibility = "Today.focusVisibility"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func heatmapActivityTypes() -> [String] {
        userDefaults.stringArray(forKey: Key.heatmapActivityTypes.rawValue) ?? []
    }

    func setHeatmapActivityTypes(_ activityTypes: [String]) {
        userDefaults.set(activityTypes, forKey: Key.heatmapActivityTypes.rawValue)
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
        let dueDateVisibilityRawValue = userDefaults.string(forKey: Key.todayDueDateVisibility.rawValue)
        let focusVisibilityRawValue = userDefaults.string(forKey: Key.todayFocusVisibility.rawValue)

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
        userDefaults.set(options.dueDateVisibility.rawValue, forKey: Key.todayDueDateVisibility.rawValue)
        userDefaults.set(options.focusVisibility.rawValue, forKey: Key.todayFocusVisibility.rawValue)
    }

    func clear() {
        Key.allCases.forEach {
            userDefaults.removeObject(forKey: $0.rawValue)
        }
    }
}
