//
//  WidgetSnapshotPreferenceStore.swift
//  Data
//
//  Created by opfic on 5/14/26.
//

import Foundation
import Core

public protocol WidgetSnapshotPreferenceStore {
    func heatmapActivityTypes() -> [String]
    func setHeatmapActivityTypes(_ activityTypes: [String])
    func selectedActivityKinds() -> Set<ActivityKind>
    func todayDisplayOptions() -> TodayDisplayOptions
    func setTodayDisplayOptions(_ options: TodayDisplayOptions)
    func clear()
}
