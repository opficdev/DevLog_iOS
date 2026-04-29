//
//  HeatmapWidgetSnapshot.swift
//  DevLogWidget
//
//  Created by opfic on 4/17/26.
//

import Foundation

struct HeatmapWidgetSnapshot: Decodable, Equatable {
    let generatedAt: Date
    let quarterStart: Date
    let selectedActivityKindRawValues: [String]
    let maxCount: Int
    let months: [WidgetHeatmapMonthSnapshot]

    private enum CodingKeys: String, CodingKey {
        case generatedAt
        case quarterStart
        case monthStart
        case selectedActivityKindRawValues
        case maxCount
        case months
        case weeks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        selectedActivityKindRawValues = try container.decode([String].self, forKey: .selectedActivityKindRawValues)
        maxCount = try container.decode(Int.self, forKey: .maxCount)

        if let quarterStart = try container.decodeIfPresent(Date.self, forKey: .quarterStart),
           let months = try container.decodeIfPresent([WidgetHeatmapMonthSnapshot].self, forKey: .months) {
            self.quarterStart = quarterStart
            self.months = months
        } else {
            let monthStart = try container.decode(Date.self, forKey: .monthStart)
            let weeks = try container.decode([WidgetHeatmapWeekSnapshot].self, forKey: .weeks)
            self.quarterStart = monthStart
            self.months = [
                WidgetHeatmapMonthSnapshot(
                    monthStart: monthStart,
                    weeks: weeks
                )
            ]
        }
    }
}

struct WidgetHeatmapMonthSnapshot: Decodable, Equatable {
    let monthStart: Date
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
