//
//  HeatmapWidgetSnapshot.swift
//  DevLogWidget
//
//  Created by opfic on 4/17/26.
//

import Foundation

struct HeatmapWidgetSnapshot: Decodable, Equatable {
    let generatedAt: Date
    let monthStart: Date
    let selectedActivityKindRawValues: [String]
    let maxCount: Int
    let weeks: [WidgetHeatmapWeekSnapshot]
}

struct WidgetHeatmapWeekSnapshot: Decodable, Equatable {
    let id: Int
    let days: [WidgetHeatmapDaySnapshot]
}

struct WidgetHeatmapDaySnapshot: Decodable, Equatable {
    let date: Date
    let createdCount: Int
    let completedCount: Int
    let deletedCount: Int
    let isVisible: Bool
}
