//
//  WidgetSnapshotPreferenceStore.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol WidgetSnapshotPreferenceStore {
    func heatmapActivityTypes() -> [String]
    func setHeatmapActivityTypes(_ activityTypes: [String])
    func selectedActivityKinds() -> Set<ActivityKind>
    func todayDisplayOptions() -> TodayDisplayOptions
    func setTodayDisplayOptions(_ options: TodayDisplayOptions)
    func clear()
}
