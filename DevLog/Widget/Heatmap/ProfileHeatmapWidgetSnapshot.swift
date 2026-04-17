//
//  ProfileHeatmapWidgetSnapshot.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation

struct ProfileHeatmapWidgetSnapshot: Codable, Equatable {
    let generatedAt: Date
    let monthStart: Date
    let selectedActivityKindRawValues: [String]
    let maxCount: Int
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
