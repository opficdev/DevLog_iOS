//
//  ProfileFeature+Heatmap.swift
//  DevLogPresentation
//
//  Created by opfic on 6/15/26.
//

import DevLogCore
import DevLogDomain
import Foundation

private struct ProfileHeatmapActivityCounts {
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

private struct ProfileHeatmapActivityEntry {
    var todo: Todo
    var activityKinds: Set<ActivityKind>
}

extension ProfileFeature {
    static func quarterStart(for date: Date) -> Date? {
        let month = Calendar.current.component(.month, from: date)
        let startMonth = ((month - 1) / 3) * 3 + 1
        var components = Calendar.current.dateComponents([.year], from: date)
        components.month = startMonth
        components.day = 1
        return Calendar.current.date(from: components)
    }

    static func quarterStart(year: Int, quarter: Int) -> Date? {
        guard (1...4).contains(quarter) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = ((quarter - 1) * 3) + 1
        components.day = 1
        return Calendar.current.date(from: components)
    }

    static func canSelectQuarter(_ quarterStart: Date, state: State) -> Bool {
        guard let earliestQuarterStart = state.earliestQuarterStart,
              let currentQuarterStart = self.quarterStart(for: Date()) else { return false }
        return earliestQuarterStart <= quarterStart && quarterStart <= currentQuarterStart
    }

    static func normalizeActivityKinds(_ rawValues: [String]) -> Set<ActivityKind> {
        let selectableActivityKindRawValues = Set(ActivityKindItem.selectableItems.map(\.rawValue))

        return Set(
            rawValues
                .compactMap(ActivityKind.init(rawValue:))
                .filter { selectableActivityKindRawValues.contains($0.rawValue) }
        )
    }

    static func canMoveToQuarter(offsetMonths: Int, state: State) -> Bool {
        guard let selectedQuarterStart = state.selectedQuarterStart else { return false }
        guard let targetQuarterStart = Calendar.current.date(
            byAdding: .month,
            value: offsetMonths,
            to: selectedQuarterStart
        ) else {
            return false
        }
        return canSelectQuarter(targetQuarterStart, state: state)
    }

    static func fetchQuarterActivityData(
        from quarterStart: Date,
        fetchTodosUseCase: FetchTodosUseCase
    ) async throws -> (quarter: HeatmapQuarter, dayActivitiesByDate: [Date: [HeatmapActivityItem]]) {
        guard let nextQuarterStart = Calendar.current.date(byAdding: .month, value: 3, to: quarterStart) else {
            return (HeatmapQuarter(quarterStart: quarterStart, months: []), [:])
        }

        async let createdTodoPage = fetchTodosUseCase.execute(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: .createdAt,
                pageSize: 100,
                fetchAllPages: true
            ),
            cursor: nil
        )
        async let completedTodoPage = fetchTodosUseCase.execute(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: .completedAt,
                pageSize: 100,
                fetchAllPages: true
            ),
            cursor: nil
        )
        async let deletedTodoPage = fetchTodosUseCase.execute(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: .deletedAt,
                pageSize: 100,
                fetchAllPages: true
            ),
            cursor: nil
        )

        let (createdTodoPageResult, completedTodoPageResult, deletedTodoPageResult) = try await (
            createdTodoPage,
            completedTodoPage,
            deletedTodoPage
        )
        return makeQuarterActivityData(
            createdTodos: createdTodoPageResult.items,
            completedTodos: completedTodoPageResult.items,
            deletedTodos: deletedTodoPageResult.items,
            quarterStart: quarterStart
        )
    }

    static func makeQuarterActivityData(
        createdTodos: [Todo],
        completedTodos: [Todo],
        deletedTodos: [Todo],
        quarterStart: Date
    ) -> (quarter: HeatmapQuarter, dayActivitiesByDate: [Date: [HeatmapActivityItem]]) {
        var dailyCountsByDate: [Date: ProfileHeatmapActivityCounts] = [:]
        var activityEntriesByDate: [Date: [String: ProfileHeatmapActivityEntry]] = [:]

        for todo in createdTodos {
            appendHeatmapActivity(
                todo: todo,
                kind: .created,
                occurredAt: todo.createdAt,
                dailyCountsByDate: &dailyCountsByDate,
                activityEntriesByDate: &activityEntriesByDate
            )
        }

        for todo in completedTodos {
            guard let completedAt = todo.completedAt else { continue }
            appendHeatmapActivity(
                todo: todo,
                kind: .completed,
                occurredAt: completedAt,
                dailyCountsByDate: &dailyCountsByDate,
                activityEntriesByDate: &activityEntriesByDate
            )
        }

        for todo in deletedTodos {
            guard let deletedAt = todo.deletedAt else { continue }
            appendHeatmapActivity(
                todo: todo,
                kind: .deleted,
                occurredAt: deletedAt,
                dailyCountsByDate: &dailyCountsByDate,
                activityEntriesByDate: &activityEntriesByDate
            )
        }

        let quarter = HeatmapQuarter(
            quarterStart: quarterStart,
            months: makeActivityMonths(dailyCountsByDate: dailyCountsByDate, quarterStart: quarterStart)
        )
        let dayActivitiesByDate = activityEntriesByDate.mapValues { activityEntries in
            activityEntries.values.compactMap { activityEntry in
                HeatmapActivityItem(
                    todo: activityEntry.todo,
                    activityKinds: orderedActivityKinds(from: activityEntry.activityKinds)
                )
            }
            .sorted()
        }
        return (quarter, dayActivitiesByDate)
    }

    private static func makeActivityMonths(
        dailyCountsByDate: [Date: ProfileHeatmapActivityCounts],
        quarterStart: Date
    ) -> [HeatmapMonth] {
        let monthStarts = (0..<3).compactMap {
            Calendar.current.date(byAdding: .month, value: $0, to: quarterStart)
        }

        return monthStarts.map { monthStart in
            makeActivityMonth(
                monthStart: monthStart,
                dailyCountsByDate: dailyCountsByDate
            )
        }
    }

    private static func makeActivityMonth(
        monthStart: Date,
        dailyCountsByDate: [Date: ProfileHeatmapActivityCounts]
    ) -> HeatmapMonth {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: monthStart),
              let monthLastDay = Calendar.current.date(byAdding: .day, value: -1, to: monthInterval.end),
              let firstWeekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: monthLastDay) else {
            return HeatmapMonth(monthStart: monthStart, weeks: [])
        }

        var days: [HeatmapDay] = []
        var cursor = firstWeekInterval.start
        while cursor < lastWeekInterval.end {
            let normalizedDate = Calendar.current.startOfDay(for: cursor)
            let isInMonth = Calendar.current.isDate(normalizedDate, equalTo: monthStart, toGranularity: .month)
            let dailyCounts = dailyCountsByDate[normalizedDate] ?? ProfileHeatmapActivityCounts()
            let createdCount = isInMonth ? dailyCounts.createdCount : 0
            let completedCount = isInMonth ? dailyCounts.completedCount : 0
            let deletedCount = isInMonth ? dailyCounts.deletedCount : 0
            days.append(
                HeatmapDay(
                    date: normalizedDate,
                    createdCount: createdCount,
                    completedCount: completedCount,
                    deletedCount: deletedCount,
                    isVisible: isInMonth
                )
            )
            guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        var weeks: [[HeatmapDay]] = []
        var index = 0
        while index < days.count {
            let endIndex = min(index + 7, days.count)
            weeks.append(Array(days[index..<endIndex]))
            index += 7
        }

        return HeatmapMonth(monthStart: monthStart, weeks: weeks)
    }

    private static func appendHeatmapActivity(
        todo: Todo,
        kind: ActivityKind,
        occurredAt: Date,
        dailyCountsByDate: inout [Date: ProfileHeatmapActivityCounts],
        activityEntriesByDate: inout [Date: [String: ProfileHeatmapActivityEntry]]
    ) {
        let dayStart = Calendar.current.startOfDay(for: occurredAt)
        var heatmapActivityCounts = dailyCountsByDate[dayStart] ?? ProfileHeatmapActivityCounts()
        heatmapActivityCounts.increment(kind)
        dailyCountsByDate[dayStart] = heatmapActivityCounts

        var activityEntries = activityEntriesByDate[dayStart] ?? [:]
        var heatmapActivityEntry = activityEntries[todo.id] ?? ProfileHeatmapActivityEntry(
            todo: todo,
            activityKinds: []
        )
        heatmapActivityEntry.todo = todo
        heatmapActivityEntry.activityKinds.insert(kind)
        activityEntries[todo.id] = heatmapActivityEntry
        activityEntriesByDate[dayStart] = activityEntries
    }

    private static func orderedActivityKinds(from activityKinds: Set<ActivityKind>) -> [ActivityKind] {
        let orderedActivityKinds: [ActivityKind] = [.created, .completed, .deleted]
        return orderedActivityKinds.filter { activityKinds.contains($0) }
    }
}
