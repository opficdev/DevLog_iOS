//
//  ProfileTrendChartView.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Charts
import SwiftUI

struct ProfileTrendChartView: View {
    let trendPoints: [ProfileWeeklyTrendPoint]
    let selectedActivityTypes: Set<ProfileActivityType>

    private let chartHeight: CGFloat = 190
    private let createdColor = Color.orange
    private let completedColor = Color.blue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("주간 추세")
                    .font(.subheadline)
                    .bold()

                Spacer()

                HStack(spacing: 10) {
                    if selectedActivityTypes.contains(.created) {
                        legendItem(title: ProfileActivityType.created.title, color: createdColor)
                    }
                    if selectedActivityTypes.contains(.completed) {
                        legendItem(title: ProfileActivityType.completed.title, color: completedColor)
                    }
                }
            }

            if hasVisibleActivity {
                Chart {
                    if selectedActivityTypes.contains(.created) {
                        createdSeries
                    }

                    if selectedActivityTypes.contains(.completed) {
                        completedSeries
                    }
                }
                .chartLegend(.hidden)
                .chartXScale(
                    domain: xDomain,
                    range: .plotDimension(startPadding: 4, endPadding: 14)
                )
                .chartXAxis {
                    AxisMarks(values: axisWeekIndices) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.quaternary)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.quaternary)
                        AxisValueLabel {
                            if let weekIndex = value.as(Int.self) {
                                Text("\(weekIndex)주")
                                    .font(.caption2)
                                    .fixedSize()
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: yAxisValues) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.quaternary)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.quaternary)
                        AxisValueLabel()
                    }
                }
                .chartYScale(domain: yDomain)
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color(.systemGray6).opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(height: chartHeight)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("이 분기에는 선택한 활동이 없어요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: chartHeight)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.6))
                )
            }
        }
    }

    private var axisWeekIndices: [Int] {
        let weekIndices = trendPoints.map(\.weekIndex)
        guard weekIndices.count > 6 else { return weekIndices }

        var labels = Set<Int>()
        let lastIndex = weekIndices.count - 1

        for (offset, weekIndex) in weekIndices.enumerated() {
            if offset == 0 || offset == lastIndex || offset.isMultiple(of: 2) {
                labels.insert(weekIndex)
            }
        }

        return labels.sorted()
    }

    private var visibleCounts: [Int] {
        trendPoints.flatMap { point in
            ProfileActivityType.allCases.compactMap { activityType in
                guard selectedActivityTypes.contains(activityType) else { return nil }
                return point.count(for: activityType)
            }
        }
    }

    private var maxVisibleCount: Int {
        max(visibleCounts.max() ?? 0, 1)
    }

    private var xDomain: ClosedRange<Int> {
        let upperBound = trendPoints.map(\.weekIndex).max() ?? 1
        return 1...upperBound
    }

    private var yAxisValues: [Int] {
        if maxVisibleCount <= 4 {
            return Array(0...maxVisibleCount)
        }

        let step = max(Int(ceil(Double(maxVisibleCount) / 4)), 1)
        var values = Array(stride(from: 0, through: maxVisibleCount, by: step))
        if values.last != maxVisibleCount {
            values.append(maxVisibleCount)
        }
        return values
    }

    private var yDomain: ClosedRange<Double> {
        let upperBound = Double(maxVisibleCount)
        let upperPadding = max(0.8, upperBound * 0.15)
        let lowerPadding = max(0.6, upperBound * 0.08)
        return -lowerPadding...(upperBound + upperPadding)
    }

    private var hasVisibleActivity: Bool {
        visibleCounts.contains { $0 > 0 }
    }

    @ChartContentBuilder
    private var createdSeries: some ChartContent {
        ForEach(trendPoints) { point in
            LineMark(
                x: .value("주차", point.weekIndex),
                y: .value(ProfileActivityType.created.title, point.createdCount),
                series: .value("활동", ProfileActivityType.created.title)
            )
            .foregroundStyle(createdColor)
            .lineStyle(StrokeStyle(lineWidth: 2.5))

            PointMark(
                x: .value("주차", point.weekIndex),
                y: .value(ProfileActivityType.created.title, point.createdCount)
            )
            .foregroundStyle(createdColor)
        }
    }

    @ChartContentBuilder
    private var completedSeries: some ChartContent {
        ForEach(trendPoints) { point in
            LineMark(
                x: .value("주차", point.weekIndex),
                y: .value(ProfileActivityType.completed.title, point.completedCount),
                series: .value("활동", ProfileActivityType.completed.title)
            )
            .foregroundStyle(completedColor)
            .lineStyle(StrokeStyle(lineWidth: 2.5))

            PointMark(
                x: .value("주차", point.weekIndex),
                y: .value(ProfileActivityType.completed.title, point.completedCount)
            )
            .foregroundStyle(completedColor)
        }
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
