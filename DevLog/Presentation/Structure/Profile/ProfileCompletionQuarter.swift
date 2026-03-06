//
//  ProfileCompletionQuarter.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileCompletionQuarter: Identifiable, Hashable {
    var id: Date { quarterStart }
    let quarterStart: Date
    let months: [ProfileCompletionMonth]

    var weeklyTrendPoints: [ProfileWeeklyTrendPoint] {
        Self.makeWeeklyTrendPoints(from: months, calendar: .current)
    }

    var maxCount: Int {
        months
            .flatMap { $0.weeks }
            .flatMap { $0 }
            .filter { $0.isInMonth }
            .map { $0.createdCount + $0.completedCount }
            .max() ?? 0
    }

    static func makeWeeklyTrendPoints(
        from months: [ProfileCompletionMonth],
        calendar: Calendar
    ) -> [ProfileWeeklyTrendPoint] {
        let days = months
            .flatMap(\.weeks)
            .flatMap { $0 }
            .filter(\.isInMonth)
        let groupedByWeekStart = Dictionary(grouping: days) { day in
            calendar.dateInterval(of: .weekOfYear, for: day.date)?.start
                ?? calendar.startOfDay(for: day.date)
        }

        return groupedByWeekStart.keys.sorted().enumerated().map { index, weekStart in
            let weekDays = groupedByWeekStart[weekStart, default: []]
            return ProfileWeeklyTrendPoint(
                weekStart: weekStart,
                weekIndex: index + 1,
                createdCount: weekDays.reduce(0) { $0 + $1.createdCount },
                completedCount: weekDays.reduce(0) { $0 + $1.completedCount }
            )
        }
    }
}
