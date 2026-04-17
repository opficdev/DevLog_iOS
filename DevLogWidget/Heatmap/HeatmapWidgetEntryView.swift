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
        VStack(alignment: .leading, spacing: 8) {
            Text("이번 달 히트맵")
                .font(.headline)

            Spacer()

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
        if widgetFamily == .systemSmall {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(snapshot.maxCount)")
                    .font(.title)
                    .bold()
                Text("이번 달 최대 활동 수")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            WidgetPlaceholderCard(
                title: "이번 달 히트맵",
                message: "저장된 주차 \(snapshot.weeks.count)개"
            )
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if widgetFamily == .systemSmall {
            Text("앱을 열어\n히트맵을 준비하세요")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            WidgetPlaceholderCard(
                title: "이번 달 히트맵",
                message: "데이터 연결 전"
            )
            .frame(maxWidth: .infinity)
        }
    }
}
