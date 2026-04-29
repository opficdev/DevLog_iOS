//
//  WidgetHeatmapGrid.swift
//  DevLogWidget
//
//  Created by opfic on 4/28/26.
//

import SwiftUI

struct WidgetHeatmapGrid: View {
    let months: [WidgetHeatmapMonthSnapshot]
    let selectedActivityKindRawValues: [String]
    let maxCount: Int
    let showsMonthTitles: Bool

    var body: some View {
        GeometryReader { proxy in
            let layout = WidgetHeatmapLayout(
                availableWidth: proxy.size.width,
                availableHeight: proxy.size.height,
                weekCounts: months.map(\.weeks.count),
                showsMonthTitles: showsMonthTitles
            )

            HStack(alignment: .top, spacing: layout.weekdayLabelSpacing) {
                WidgetHeatmapWeekdayLabels(layout: layout)

                HStack(alignment: .top, spacing: layout.monthSpacing) {
                    ForEach(months, id: \.monthStart) { month in
                        WidgetHeatmapMonthGrid(
                            month: month,
                            layout: layout,
                            selectedActivityKindRawValues: selectedActivityKindRawValues,
                            maxCount: maxCount,
                            showsMonthTitle: showsMonthTitles
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

struct WidgetHeatmapPlaceholderGrid: View {
    let weekCounts: [Int]
    let showsMonthTitles: Bool

    var body: some View {
        GeometryReader { proxy in
            let layout = WidgetHeatmapLayout(
                availableWidth: proxy.size.width,
                availableHeight: proxy.size.height,
                weekCounts: weekCounts,
                showsMonthTitles: showsMonthTitles
            )

            HStack(alignment: .top, spacing: layout.weekdayLabelSpacing) {
                WidgetHeatmapWeekdayLabels(layout: layout)

                HStack(alignment: .top, spacing: layout.monthSpacing) {
                    ForEach(Array(weekCounts.enumerated()), id: \.offset) { _, weekCount in
                        WidgetHeatmapPlaceholderMonthGrid(
                            weekCount: weekCount,
                            layout: layout,
                            showsMonthTitle: showsMonthTitles
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct WidgetHeatmapWeekdayLabels: View {
    let layout: WidgetHeatmapLayout
    private let orderedWeekdays = Array(1...7)
    private let weekdayLabels = [
        2: "월",
        4: "수",
        6: "금"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: layout.cellSpacing) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                weekdayLabel(for: weekday)
            }
        }
        .padding(.top, layout.weekdayTopPadding)
    }

    @ViewBuilder
    private func weekdayLabel(for weekday: Int) -> some View {
        if let label = weekdayLabels[weekday] {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(
                    width: layout.weekdayLabelWidth,
                    height: layout.cellSize,
                    alignment: .leading
                )
        } else {
            Color.clear
                .frame(
                    width: layout.weekdayLabelWidth,
                    height: layout.cellSize
                )
        }
    }
}

private struct WidgetHeatmapMonthGrid: View {
    let month: WidgetHeatmapMonthSnapshot
    let layout: WidgetHeatmapLayout
    let selectedActivityKindRawValues: [String]
    let maxCount: Int
    let showsMonthTitle: Bool
    private let orderedWeekdays = Array(1...7)

    var body: some View {
        VStack(alignment: .leading, spacing: layout.monthTitleSpacing) {
            if showsMonthTitle {
                Text(month.monthStart.formatted(.dateTime.month(.abbreviated)))
                    .frame(height: layout.cellSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: layout.cellSpacing) {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    HStack(spacing: layout.cellSpacing) {
                        ForEach(month.weeks, id: \.id) { week in
                            let day = week.days.first {
                                Calendar.current.component(.weekday, from: $0.date) == weekday
                            }

                            RoundedRectangle(cornerRadius: layout.cellCornerRadius)
                                .fill(fillColor(for: day))
                                .frame(width: layout.cellSize, height: layout.cellSize)
                        }
                    }
                }
            }
        }
    }

    private func fillColor(for day: WidgetHeatmapDaySnapshot?) -> Color {
        guard let day, day.isVisible else { return .clear }

        let count = dayCount(for: day)
        if count == 0 {
            return Color(.systemGray5)
        }

        return Color.blue.opacity(opacity(for: count, max: maxCount))
    }

    private func dayCount(for day: WidgetHeatmapDaySnapshot) -> Int {
        let selectedActivityKindRawValues = Set(selectedActivityKindRawValues)
        var value = 0

        if selectedActivityKindRawValues.contains(WidgetHeatmapActivityKind.created.rawValue) {
            value += day.createdCount
        }

        if selectedActivityKindRawValues.contains(WidgetHeatmapActivityKind.completed.rawValue) {
            value += day.completedCount
        }

        if selectedActivityKindRawValues.contains(WidgetHeatmapActivityKind.deleted.rawValue) {
            value += day.deletedCount
        }

        return value
    }

    private func opacity(for count: Int, max: Int) -> Double {
        guard 0 < count && 0 < max else { return 0 }
        let ratio = Double(count) / Double(max)
        return ceil(ratio * 10) / 10
    }
}

private enum WidgetHeatmapActivityKind: String {
    case created
    case completed
    case deleted
}

private struct WidgetHeatmapPlaceholderMonthGrid: View {
    let weekCount: Int
    let layout: WidgetHeatmapLayout
    let showsMonthTitle: Bool
    private let orderedWeekdays = Array(1...7)

    var body: some View {
        VStack(alignment: .leading, spacing: layout.monthTitleSpacing) {
            if showsMonthTitle {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: layout.cellSize * 3, height: 8)
                    .frame(height: layout.cellSize, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: layout.cellSpacing) {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    HStack(spacing: layout.cellSpacing) {
                        ForEach(0..<weekCount, id: \.self) { weekIndex in
                            RoundedRectangle(cornerRadius: layout.cellCornerRadius)
                                .fill(Color.secondary.opacity(opacity(weekday: weekday, weekIndex: weekIndex)))
                                .frame(width: layout.cellSize, height: layout.cellSize)
                        }
                    }
                }
            }
        }
    }

    private func opacity(weekday: Int, weekIndex: Int) -> Double {
        switch (weekday + weekIndex) % 4 {
        case 0:
            return 1 / 8
        case 1:
            return 1 / 5
        case 2:
            return 1 / 4
        default:
            return 3 / 20
        }
    }
}
