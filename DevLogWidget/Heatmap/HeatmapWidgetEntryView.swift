//
//  HeatmapWidgetEntryView.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import WidgetKit

struct HeatmapWidgetEntryView: View {
    let entry: HeatmapWidgetEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                content(snapshot)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func content(_ snapshot: HeatmapWidgetSnapshot) -> some View {
        switch widgetFamily {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 4) {
                header(title: "이번 달 히트맵")
                WidgetHeatmapGrid(
                    months: currentMonths(from: snapshot),
                    selectedActivityKindRawValues: snapshot.selectedActivityKindRawValues,
                    maxCount: snapshot.maxCount,
                    showsMonthTitles: false
                )
            }
        case .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                header(title: "이번 분기 히트맵")
                WidgetHeatmapGrid(
                    months: snapshot.months,
                    selectedActivityKindRawValues: snapshot.selectedActivityKindRawValues,
                    maxCount: snapshot.maxCount,
                    showsMonthTitles: true
                )
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch widgetFamily {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                Text("이번 달 히트맵")
                    .font(.headline)
                GeometryReader { proxy in
                    placeholderHeatmapGrid(
                        monthCount: 1,
                        availableSize: proxy.size,
                        showsMonthTitles: false
                    )
                }
                .frame(height: 72)
            }
        case .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                header(title: "이번 분기 히트맵")
                GeometryReader { proxy in
                    placeholderHeatmapGrid(
                        monthCount: 3,
                        availableSize: proxy.size,
                        showsMonthTitles: true
                    )
                }
                .frame(height: 80)
            }
        default:
            EmptyView()
        }
    }

    private func header(title: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.headline)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private func currentMonths(from snapshot: HeatmapWidgetSnapshot) -> [WidgetHeatmapMonthSnapshot] {
        if let currentMonth = snapshot.months.first(where: {
            Calendar.current.isDate($0.monthStart, equalTo: snapshot.generatedAt, toGranularity: .month)
        }) {
            return [currentMonth]
        }

        return Array(snapshot.months.prefix(1))
    }

    private func placeholderHeatmapGrid(
        monthCount: Int,
        availableSize: CGSize,
        showsMonthTitles: Bool
    ) -> some View {
        let resolvedMonthCount = max(monthCount, 1)
        let columnCount = showsMonthTitles ? 5 : 6
        let monthSpacing = showsMonthTitles ? availableSize.width / 18 : 0
        let cellSpacing: CGFloat = 3
        let monthTitleHeight: CGFloat = showsMonthTitles ? 8 : 0
        let monthTitleSpacing: CGFloat = showsMonthTitles ? 6 : 0
        let totalMonthSpacing = monthSpacing * CGFloat(max(resolvedMonthCount - 1, 0))
        let monthWidth = max((availableSize.width - totalMonthSpacing) / CGFloat(resolvedMonthCount), 0)
        let widthBasedCellSize = max(
            (monthWidth - cellSpacing * CGFloat(max(columnCount - 1, 0))) / CGFloat(columnCount),
            0
        )
        let verticalFixedHeight = monthTitleHeight
            + monthTitleSpacing
            + cellSpacing * CGFloat(max(7 - 1, 0))
        let heightBasedCellSize = max((availableSize.height - verticalFixedHeight) / 7, 0)
        let cellSize = min(widthBasedCellSize, heightBasedCellSize)

        return HStack(alignment: .top, spacing: monthSpacing) {
            ForEach(0..<resolvedMonthCount, id: \.self) { _ in
                placeholderHeatmapMonth(
                    columnCount: columnCount,
                    cellSize: cellSize,
                    cellSpacing: cellSpacing,
                    monthTitleHeight: monthTitleHeight,
                    monthTitleSpacing: monthTitleSpacing,
                    showsMonthTitles: showsMonthTitles
                )
            }
        }
    }

    private func placeholderHeatmapMonth(
        columnCount: Int,
        cellSize: CGFloat,
        cellSpacing: CGFloat,
        monthTitleHeight: CGFloat,
        monthTitleSpacing: CGFloat,
        showsMonthTitles: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: monthTitleSpacing) {
            if showsMonthTitles {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: cellSize * 3, height: monthTitleHeight)
            }

            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(0..<columnCount, id: \.self) { columnIndex in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { rowIndex in
                            placeholderHeatmapCell(
                                columnIndex: columnIndex,
                                rowIndex: rowIndex,
                                size: cellSize
                            )
                        }
                    }
                }
            }
        }
    }

    private func placeholderHeatmapCell(
        columnIndex: Int,
        rowIndex: Int,
        size: CGFloat
    ) -> some View {
        let opacity = placeholderHeatmapCellOpacity(columnIndex: columnIndex, rowIndex: rowIndex)

        return RoundedRectangle(cornerRadius: max(2, size / 5))
            .fill(Color.secondary.opacity(opacity))
            .frame(width: size, height: size)
    }

    private func placeholderHeatmapCellOpacity(
        columnIndex: Int,
        rowIndex: Int
    ) -> Double {
        switch (columnIndex + rowIndex) % 4 {
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
