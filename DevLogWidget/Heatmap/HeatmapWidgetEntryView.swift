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
                Text("앱을 열어\n히트맵을 준비하세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .systemMedium:
            WidgetPlaceholderCard(
                title: "이번 분기 히트맵",
                message: "데이터 연결 전"
            )
            .frame(maxWidth: .infinity)
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
}
