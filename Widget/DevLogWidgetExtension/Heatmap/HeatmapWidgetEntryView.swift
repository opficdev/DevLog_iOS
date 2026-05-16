//
//  HeatmapWidgetEntryView.swift
//  DevLogWidgetExtension
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import WidgetKit
import DevLogWidgetCore

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
                header(title: "widget_heatmap_current_month_title")
                WidgetHeatmapGrid(
                    months: currentMonths(from: snapshot),
                    selectedActivityKindRawValues: snapshot.selectedActivityKindRawValues,
                    maxCount: snapshot.maxCount,
                    showsMonthTitles: false
                )
            }
        case .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                header(title: "widget_heatmap_current_quarter_title")
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
        let shape = WidgetHeatmapPlaceholderShape(date: entry.date)

        switch widgetFamily {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                header(title: "widget_heatmap_current_month_title")
                WidgetHeatmapPlaceholderGrid(
                    months: shape.currentMonths,
                    showsMonthTitles: false
                )
            }
        case .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                header(title: "widget_heatmap_current_quarter_title")
                WidgetHeatmapPlaceholderGrid(
                    months: shape.quarterMonths,
                    showsMonthTitles: true
                )
            }
        default:
            EmptyView()
        }
    }

    private func header(title: LocalizedStringKey) -> some View {
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
