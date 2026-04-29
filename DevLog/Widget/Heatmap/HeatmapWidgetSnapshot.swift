//
//  HeatmapWidgetSnapshot.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation

struct HeatmapWidgetSnapshot: Codable, Equatable {
    let generatedAt: Date
    let quarterStart: Date
    let selectedActivityKindRawValues: [String]
    let maxCount: Int
    let months: [WidgetHeatmapMonthSnapshot]
}

struct WidgetHeatmapMonthSnapshot: Codable, Equatable {
    let monthStart: Date
    let weeks: [WidgetHeatmapWeekSnapshot]
}

struct WidgetHeatmapWeekSnapshot: Codable, Equatable {
    let id: Int
    let days: [WidgetHeatmapDaySnapshot]
}

struct WidgetHeatmapDaySnapshot: Codable, Equatable {
    let date: Date
    let createdCount: Int
    let completedCount: Int
    let deletedCount: Int
    let isVisible: Bool
}
