//
//  WidgetHeatmapPlaceholderShapeTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/30/26.
//

import Foundation
import Testing
@testable import DevLog

struct WidgetHeatmapPlaceholderShapeTests {
    @Test("Heatmap 위젯 placeholder는 현재 월과 분기의 실제 날짜 위치를 사용한다")
    func heatmap_위젯_placeholder는_현재_월과_분기의_실제_날짜_위치를_사용한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 15)))

        let widgetHeatmapPlaceholderShape = WidgetHeatmapPlaceholderShape(
            date: date,
            calendar: calendar
        )

        #expect(widgetHeatmapPlaceholderShape.currentMonthWeekCounts == [6])
        #expect(widgetHeatmapPlaceholderShape.quarterWeekCounts == [5, 6, 5])

        let currentMonth = try #require(widgetHeatmapPlaceholderShape.currentMonths.first)
        #expect(currentMonth.weeks.count == 6)
        #expect(currentMonth.weeks[0].days.map(\.isVisible) == [
            false,
            false,
            false,
            false,
            false,
            true,
            true
        ])
        #expect(currentMonth.weeks[5].days.map(\.isVisible) == [
            true,
            false,
            false,
            false,
            false,
            false,
            false
        ])

        let quarterMonths = widgetHeatmapPlaceholderShape.quarterMonths
        #expect(quarterMonths.map(\.weeks.count) == [5, 6, 5])
        #expect(quarterMonths[0].weeks[0].days.map(\.isVisible) == [
            false,
            false,
            false,
            true,
            true,
            true,
            true
        ])
        #expect(quarterMonths[2].weeks[4].days.map(\.isVisible) == [
            true,
            true,
            true,
            false,
            false,
            false,
            false
        ])
    }
}
