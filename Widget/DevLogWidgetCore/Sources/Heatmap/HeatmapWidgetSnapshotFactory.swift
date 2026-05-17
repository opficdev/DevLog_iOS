//
//  HeatmapWidgetSnapshotFactory.swift
//  DevLogWidgetCore
//
//  Created by opfic on 4/17/26.
//

import Foundation
import DevLogCore
import DevLogData

public struct HeatmapWidgetSnapshotFactory {
    fileprivate struct DailyCounts {
        var createdCount = 0
        var completedCount = 0
        var deletedCount = 0

        mutating func increment(_ activityKind: ActivityKind) {
            switch activityKind {
            case .created:
                createdCount += 1
            case .completed:
                completedCount += 1
            case .deleted:
                deletedCount += 1
            }
        }
    }

    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func makeSnapshot(
        createdTodos: [WidgetTodoSnapshot],
        completedTodos: [WidgetTodoSnapshot],
        deletedTodos: [WidgetTodoSnapshot],
        selectedActivityKinds: Set<ActivityKind>,
        quarterStart: Date,
        now: Date = Date()
    ) -> HeatmapWidgetSnapshot {
        let normalizedQuarterStart = calendar.startOfQuarter(for: quarterStart)
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: normalizedQuarterStart) else {
            return HeatmapWidgetSnapshot(
                generatedAt: now,
                quarterStart: normalizedQuarterStart,
                selectedActivityKindRawValues: orderedActivityKinds(from: selectedActivityKinds).map(\.rawValue),
                maxCount: 0,
                months: []
            )
        }
        let dailyCountsByDate = makeDailyCountsByDate(
            createdTodos: createdTodos,
            completedTodos: completedTodos,
            deletedTodos: deletedTodos,
            quarterStart: normalizedQuarterStart,
            nextQuarterStart: nextQuarterStart
        )
        let months = makeMonths(
            quarterStart: normalizedQuarterStart,
            dailyCountsByDate: dailyCountsByDate
        )

        return HeatmapWidgetSnapshot(
            generatedAt: now,
            quarterStart: normalizedQuarterStart,
            selectedActivityKindRawValues: orderedActivityKinds(from: selectedActivityKinds).map(\.rawValue),
            maxCount: maxCount(
                from: months,
                selectedActivityKinds: selectedActivityKinds
            ),
            months: months
        )
    }
}

private extension HeatmapWidgetSnapshotFactory {
    func makeDailyCountsByDate(
        createdTodos: [WidgetTodoSnapshot],
        completedTodos: [WidgetTodoSnapshot],
        deletedTodos: [WidgetTodoSnapshot],
        quarterStart: Date,
        nextQuarterStart: Date
    ) -> [Date: DailyCounts] {
        var dailyCountsByDate = [Date: DailyCounts]()

        for todo in createdTodos {
            appendCount(
                activityKind: .created,
                occurredAt: todo.createdAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart,
                dailyCountsByDate: &dailyCountsByDate
            )
        }

        for todo in completedTodos {
            guard let completedAt = todo.completedAt else { continue }
            appendCount(
                activityKind: .completed,
                occurredAt: completedAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart,
                dailyCountsByDate: &dailyCountsByDate
            )
        }

        for todo in deletedTodos {
            guard let deletedAt = todo.deletedAt else { continue }
            appendCount(
                activityKind: .deleted,
                occurredAt: deletedAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart,
                dailyCountsByDate: &dailyCountsByDate
            )
        }

        return dailyCountsByDate
    }

    func appendCount(
        activityKind: ActivityKind,
        occurredAt: Date,
        quarterStart: Date,
        nextQuarterStart: Date,
        dailyCountsByDate: inout [Date: DailyCounts]
    ) {
        guard quarterStart <= occurredAt && occurredAt < nextQuarterStart else { return }

        let dayStart = calendar.startOfDay(for: occurredAt)
        var dailyCounts = dailyCountsByDate[dayStart] ?? DailyCounts()
        dailyCounts.increment(activityKind)
        dailyCountsByDate[dayStart] = dailyCounts
    }

    func makeMonths(
        quarterStart: Date,
        dailyCountsByDate: [Date: DailyCounts]
    ) -> [WidgetHeatmapMonthSnapshot] {
        let monthStarts = (0..<3).compactMap {
            calendar.date(byAdding: .month, value: $0, to: quarterStart)
        }

        return monthStarts.map { monthStart in
            WidgetHeatmapMonthSnapshot(
                monthStart: monthStart,
                weeks: makeWeeks(
                    monthStart: monthStart,
                    dailyCountsByDate: dailyCountsByDate
                )
            )
        }
    }

    func makeWeeks(
        monthStart: Date,
        dailyCountsByDate: [Date: DailyCounts]
    ) -> [WidgetHeatmapWeekSnapshot] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart),
              let monthLastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthLastDay) else {
            return []
        }

        var days = [WidgetHeatmapDaySnapshot]()
        var cursor = firstWeekInterval.start

        while cursor < lastWeekInterval.end {
            let normalizedDate = calendar.startOfDay(for: cursor)
            let isVisible = calendar.isDate(
                normalizedDate,
                equalTo: monthStart,
                toGranularity: .month
            )
            let dailyCounts = dailyCountsByDate[normalizedDate] ?? DailyCounts()

            days.append(
                WidgetHeatmapDaySnapshot(
                    date: normalizedDate,
                    createdCount: isVisible ? dailyCounts.createdCount : 0,
                    completedCount: isVisible ? dailyCounts.completedCount : 0,
                    deletedCount: isVisible ? dailyCounts.deletedCount : 0,
                    isVisible: isVisible
                )
            )

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        var weeks = [WidgetHeatmapWeekSnapshot]()
        var index = 0

        while index < days.count {
            let endIndex = min(index + 7, days.count)
            weeks.append(
                WidgetHeatmapWeekSnapshot(
                    id: weeks.count,
                    days: Array(days[index..<endIndex])
                )
            )
            index += 7
        }

        return weeks
    }

    func maxCount(
        from months: [WidgetHeatmapMonthSnapshot],
        selectedActivityKinds: Set<ActivityKind>
    ) -> Int {
        months
            .flatMap(\.weeks)
            .flatMap(\.days)
            .filter(\.isVisible)
            .map { day in
                dayCount(
                    for: day,
                    selectedActivityKinds: selectedActivityKinds
                )
            }
            .max() ?? 0
    }

    func dayCount(
        for day: WidgetHeatmapDaySnapshot,
        selectedActivityKinds: Set<ActivityKind>
    ) -> Int {
        var value = 0

        if selectedActivityKinds.contains(.created) {
            value += day.createdCount
        }

        if selectedActivityKinds.contains(.completed) {
            value += day.completedCount
        }

        if selectedActivityKinds.contains(.deleted) {
            value += day.deletedCount
        }

        return value
    }

    func orderedActivityKinds(from activityKinds: Set<ActivityKind>) -> [ActivityKind] {
        let orderedActivityKinds: [ActivityKind] = [.created, .completed, .deleted]
        return orderedActivityKinds.filter { activityKinds.contains($0) }
    }
}
