//
//  ProfileHeatmapView.swift
//  DevLog
//
//  Created by 최윤진 on 3/2/26.
//

import SwiftUI

struct ProfileHeatmapView: View {
    let quarter: ProfileCompletionQuarter
    let selectedActivityTypes: Set<ProfileActivityType>
    let selectedDay: ProfileCompletionDay?
    let onSelectDay: (ProfileCompletionDay) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            weekdayLabel
                .padding(.trailing, 10)
            let months = quarter.months
            ForEach(Array(zip(months.indices, months)), id: \.1) { index, month in
                MonthCompactHeatmapView(
                    month: month,
                    selectedActivityTypes: selectedActivityTypes,
                    selectedDay: selectedDay,
                    onSelectDay: onSelectDay
                )
                if index < months.count - 1 {
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var weekdayLabel: some View {
        let labels: [Int: String] = [
            2: "월",
            4: "수",
            6: "금"
        ]
        let orderedWeekdays = Array(1...7)
        let cellSize: CGFloat = 16

        VStack(alignment: .leading, spacing: 4) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                Group {
                    if let label = labels[weekday] {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: cellSize, height: cellSize)
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .padding(.top, 22)
    }
}

private struct MonthCompactHeatmapView: View {
    @Environment(\.colorScheme) private var colorScheme
    let month: ProfileCompletionMonth
    let selectedActivityTypes: Set<ProfileActivityType>
    let selectedDay: ProfileCompletionDay?
    let onSelectDay: (ProfileCompletionDay) -> Void
    private let orderedWeekdays = Array(1...7)
    private let cellSize: CGFloat = 16
    private let cellSpacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(month.monthStart.formatted(.dateTime.month(.abbreviated)))
                .frame(height: cellSize)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: cellSpacing) {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    HStack(spacing: cellSpacing) {
                        ForEach(month.weeks.indices, id: \.self) { weekIndex in
                            let day = month.weeks[weekIndex].first {
                                Calendar.current.component(.weekday, from: $0.date) == weekday
                            }

                            RoundedRectangle(cornerRadius: 3)
                                .fill(fillColor(for: day))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(selectionInnerBorderColor(for: day), lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(selectionOuterBorderColor(for: day), lineWidth: 0.8)
                                        .padding(-1)
                                )
                                .frame(width: cellSize, height: cellSize)
                                .onTapGesture {
                                    if let day, day.isInMonth {
                                        onSelectDay(day)
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    private func isSelected(_ day: ProfileCompletionDay?) -> Bool {
        guard let day, let selectedDay else { return false }
        return Calendar.current.isDate(day.date, inSameDayAs: selectedDay.date)
    }

    private func selectionInnerBorderColor(for day: ProfileCompletionDay?) -> Color {
        isSelected(day) ? .white : .clear
    }

    private func selectionOuterBorderColor(for day: ProfileCompletionDay?) -> Color {
        if isSelected(day) && colorScheme == .light {
            return Color.gray
        }
        return .clear
    }

    private func fillColor(for day: ProfileCompletionDay?) -> Color {
        guard let day, day.isInMonth else { return .clear }
        let count = dayCount(for: day)
        if count == 0 {
            return Color(UIColor.systemGray5)
        }
        return Color.blue.opacity(opacity(for: count, max: monthMaxCount))
    }

    private var monthMaxCount: Int {
        month.weeks
            .flatMap { $0 }
            .filter { $0.isInMonth }
            .map(dayCount(for:))
            .max() ?? 0
    }

    private func dayCount(for day: ProfileCompletionDay) -> Int {
        var value = 0
        if selectedActivityTypes.contains(.created) {
            value += day.createdCount
        }
        if selectedActivityTypes.contains(.completed) {
            value += day.completedCount
        }
        return value
    }

    private func opacity(for count: Int, max: Int) -> Double {
        guard 0 < count && 0 < max else { return 0 }
        let ratio = Double(count) / Double(max)
        return floor(ratio * 10) / 10
    }
}
