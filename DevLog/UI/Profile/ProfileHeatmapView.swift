//
//  ProfileHeatmapView.swift
//  DevLog
//
//  Created by 최윤진 on 3/2/26.
//

import SwiftUI

struct ProfileHeatmapView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sceneWidth) private var sceneWidth
    let quarter: ProfileCompletionQuarter
    let selectedActivityTypes: Set<ProfileActivityType>
    let selectedDay: ProfileCompletionDay?
    let onSelectDay: (ProfileCompletionDay) -> Void

    var body: some View {
        let layout = ProfileHeatmapLayout(
            availableWidth: availableWidth,
            weekCounts: quarter.months.map(\.weeks.count)
        )

        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "profile_activity_heatmap"))
                .font(.subheadline)
                .bold()
            HStack(alignment: .top, spacing: 0) {
                weekdayLabel(layout: layout)
                HStack(alignment: .top, spacing: layout.monthSpacing) {
                    ForEach(quarter.months) { month in
                        MonthCompactHeatmapView(
                            month: month,
                            maxCount: quarter.maxCount,
                            layout: layout,
                            selectedActivityTypes: selectedActivityTypes,
                            selectedDay: selectedDay,
                            onSelectDay: onSelectDay
                        )
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func weekdayLabel(layout: ProfileHeatmapLayout) -> some View {
        let labels: [Int: String] = [
            2: String(localized: "profile_weekday_mon"),
            4: String(localized: "profile_weekday_wed"),
            6: String(localized: "profile_weekday_fri")
        ]
        let orderedWeekdays = Array(1...7)
        let labelFontSize = smallestWeekdayLabelFontSize(
            labels: Array(labels.values),
            layout: layout
        )

        VStack(alignment: .leading, spacing: layout.cellSpacing) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                if let label = labels[weekday] {
                    Text(label)
                        .font(.system(size: labelFontSize))
                        .allowsTightening(true)
                        .foregroundStyle(.secondary)
                        .frame(
                            width: layout.cellSize,
                            height: layout.cellSize,
                            alignment: .leading
                        )
                        .onAppear {
                            print(labelFontSize)
                        }
                } else {
                    Color.clear
                        .frame(
                            width: layout.cellSize,
                            height: layout.cellSize
                        )
                }
            }
        }
        .padding(.top, layout.weekdayTopPadding)
    }

    private func smallestWeekdayLabelFontSize(labels: [String], layout: ProfileHeatmapLayout) -> CGFloat {
        let captionFont = UIFont.preferredFont(forTextStyle: .caption2)
        let availableWidth = max(layout.cellSize, 1)

        let fittedSizes = labels.map { label in
            let textWidth = max(
                (label as NSString).size(withAttributes: [.font: captionFont]).width,
                1
            )
            let widthRatio = availableWidth / textWidth
            return captionFont.pointSize * min(widthRatio, 1)
        }

        return max((fittedSizes.min() ?? captionFont.pointSize).rounded(.down), 1)
    }

    private var availableWidth: CGFloat {
        // ProfileView의 바깥 가로 패딩(16)과 히트맵 카드 내부 패딩(12)을 합한 값
        let horizontalPadding: CGFloat = 16 + 12
        return max(
            0,
            sceneWidth
                - safeAreaInsets.leading
                - safeAreaInsets.trailing
                - (horizontalPadding * 2)
        )
    }
}

private struct ProfileHeatmapLayout {
    let cellSize: CGFloat
    let cellSpacing: CGFloat = 4
    let monthSpacing: CGFloat = 12
    let monthTitleSpacing: CGFloat = 6

    init(availableWidth: CGFloat, weekCounts: [Int]) {
        let sanitizedWeekCounts = weekCounts.filter { 0 < $0 }
        let totalColumns = max(sanitizedWeekCounts.reduce(0, +), 1)
        let totalColumnSpacings = sanitizedWeekCounts.reduce(0) { partialResult, count in
            partialResult + max(count - 1, 0)
        }
        let fixedWidth = monthSpacing * CGFloat(max(sanitizedWeekCounts.count - 1, 0))
            + cellSpacing * CGFloat(totalColumnSpacings)
        cellSize = max(0, availableWidth - fixedWidth) / CGFloat(totalColumns + 1)
    }

    var weekdayTopPadding: CGFloat {
        cellSize + monthTitleSpacing
    }

    var cellCornerRadius: CGFloat {
        max(2, cellSize * 0.2)
    }

    var innerSelectionLineWidth: CGFloat {
        max(1.2, cellSize * 0.12)
    }
}

private struct MonthCompactHeatmapView: View {
    @Environment(\.colorScheme) private var colorScheme
    let month: ProfileCompletionMonth
    let maxCount: Int
    let layout: ProfileHeatmapLayout
    let selectedActivityTypes: Set<ProfileActivityType>
    let selectedDay: ProfileCompletionDay?
    let onSelectDay: (ProfileCompletionDay) -> Void
    private let orderedWeekdays = Array(1...7)

    var body: some View {
        VStack(alignment: .leading, spacing: layout.monthTitleSpacing) {
            Text(month.monthStart.formatted(.dateTime.month(.abbreviated)))
                .frame(height: layout.cellSize)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: layout.cellSpacing) {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    HStack(spacing: layout.cellSpacing) {
                        ForEach(month.weeks.indices, id: \.self) { weekIndex in
                            let day = month.weeks[weekIndex].first {
                                Calendar.current.component(.weekday, from: $0.date) == weekday
                            }

                            RoundedRectangle(cornerRadius: layout.cellCornerRadius)
                                .fill(fillColor(for: day, with: maxCount))
                                .stroke(
                                    selectionInnerBorderColor(for: day),
                                    lineWidth: layout.innerSelectionLineWidth
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: layout.cellCornerRadius + 1)
                                        .stroke(selectionOuterBorderColor(for: day), lineWidth: 0.8)
                                        .padding(-1)
                                )
                                .frame(width: layout.cellSize, height: layout.cellSize)
                                .onTapGesture {
                                    if let day, day.isVisible {
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

    private func fillColor(for day: ProfileCompletionDay?, with maxCount: Int) -> Color {
        guard let day, day.isVisible else { return .clear }
        let count = dayCount(for: day)
        if count == 0 {
            return Color(.systemGray5)
        }
        return Color.blue.opacity(opacity(for: count, max: maxCount))
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
        return ceil(ratio * 10) / 10
    }
}
