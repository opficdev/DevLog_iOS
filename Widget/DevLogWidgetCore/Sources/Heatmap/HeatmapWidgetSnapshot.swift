//
//  HeatmapWidgetSnapshot.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation
import DevLogDomain
import DevLogData
import DevLogWidgetShared

public struct HeatmapWidgetSnapshot: Codable, Equatable {
    let generatedAt: Date
    let quarterStart: Date
    let selectedActivityKindRawValues: [String]
    let maxCount: Int
    let months: [WidgetHeatmapMonthSnapshot]
}

public struct WidgetHeatmapMonthSnapshot: Codable, Equatable {
    let monthStart: Date
    let weeks: [WidgetHeatmapWeekSnapshot]
}

public struct WidgetHeatmapWeekSnapshot: Codable, Equatable {
    let id: Int
    let days: [WidgetHeatmapDaySnapshot]
}

public struct WidgetHeatmapDaySnapshot: Codable, Equatable {
    let date: Date
    let createdCount: Int
    let completedCount: Int
    let deletedCount: Int
    let isVisible: Bool
}
