//
//  WidgetHeatmapPlaceholderShape.swift
//  DevLogWidgetCore
//
//  Created by opfic on 4/30/26.
//

import Foundation

public struct WidgetHeatmapPlaceholderShape {
    public let currentMonths: [WidgetHeatmapPlaceholderMonthShape]
    public let quarterMonths: [WidgetHeatmapPlaceholderMonthShape]

    public var currentMonthWeekCounts: [Int] {
        currentMonths.map(\.weeks.count)
    }

    public var quarterWeekCounts: [Int] {
        quarterMonths.map(\.weeks.count)
    }

    public init(
        date: Date = Date(),
        calendar: Calendar = .current
    ) {
        let quarterStart = calendar.startOfQuarter(for: date)
        let monthStarts = (0..<3).compactMap {
            calendar.date(byAdding: .month, value: $0, to: quarterStart)
        }
        let widgetHeatmapPlaceholderMonthShapes = monthStarts.map {
            Self.makeMonth(monthStart: $0, calendar: calendar)
        }

        if let currentMonth = widgetHeatmapPlaceholderMonthShapes.first(where: {
            calendar.isDate($0.monthStart, equalTo: date, toGranularity: .month)
        }) {
            currentMonths = [currentMonth]
        } else {
            currentMonths = Array(widgetHeatmapPlaceholderMonthShapes.prefix(1))
        }

        quarterMonths = widgetHeatmapPlaceholderMonthShapes
    }

    private static func makeMonth(
        monthStart: Date,
        calendar: Calendar
    ) -> WidgetHeatmapPlaceholderMonthShape {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart),
              let monthLastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthLastDay) else {
            return WidgetHeatmapPlaceholderMonthShape(monthStart: monthStart, weeks: [])
        }

        var weeks = [WidgetHeatmapPlaceholderWeekShape]()
        var cursor = firstWeekInterval.start

        while cursor < lastWeekInterval.end {
            weeks.append(
                WidgetHeatmapPlaceholderWeekShape(
                    id: weeks.count,
                    days: makeDays(
                        weekStart: cursor,
                        monthStart: monthStart,
                        calendar: calendar
                    )
                )
            )

            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else {
                break
            }
            cursor = nextWeek
        }

        return WidgetHeatmapPlaceholderMonthShape(monthStart: monthStart, weeks: weeks)
    }

    private static func makeDays(
        weekStart: Date,
        monthStart: Date,
        calendar: Calendar
    ) -> [WidgetHeatmapPlaceholderDayShape] {
        var days = [WidgetHeatmapPlaceholderDayShape]()
        var cursor = weekStart

        for _ in 0..<7 {
            let normalizedDate = calendar.startOfDay(for: cursor)
            days.append(
                WidgetHeatmapPlaceholderDayShape(
                    date: normalizedDate,
                    isVisible: calendar.isDate(
                        normalizedDate,
                        equalTo: monthStart,
                        toGranularity: .month
                    )
                )
            )

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = nextDay
        }

        return days
    }
}

public struct WidgetHeatmapPlaceholderMonthShape: Identifiable, Hashable {
    public var id: Date { monthStart }
    public let monthStart: Date
    public let weeks: [WidgetHeatmapPlaceholderWeekShape]
}

public struct WidgetHeatmapPlaceholderWeekShape: Identifiable, Hashable {
    public let id: Int
    public let days: [WidgetHeatmapPlaceholderDayShape]
}

public struct WidgetHeatmapPlaceholderDayShape: Identifiable, Hashable {
    public var id: Date { date }
    public let date: Date
    public let isVisible: Bool
}
