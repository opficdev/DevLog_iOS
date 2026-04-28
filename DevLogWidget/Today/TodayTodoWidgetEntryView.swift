//
//  TodayTodoWidgetEntryView.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import WidgetKit

struct TodayTodoWidgetEntryView: View {
    let entry: TodayTodoWidgetEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
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
    private func content(_ snapshot: TodayWidgetSnapshot) -> some View {
        switch widgetFamily {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 4) {
                Text("\(snapshot.totalCount)")
                    .font(.system(size: 28, weight: .bold))
                Text(topItemTitle(from: snapshot))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        case .systemMedium, .systemLarge:
            WidgetPlaceholderCard(
                title: "Today",
                message: "저장된 할 일 \(snapshot.totalCount)개"
            )
            .frame(maxWidth: .infinity)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch widgetFamily {
        case .systemSmall:
            Text("앱을 열어\nToday 위젯을 준비하세요")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .systemMedium, .systemLarge:
            WidgetPlaceholderCard(
                title: "Today",
                message: "데이터 연결 전"
            )
            .frame(maxWidth: .infinity)
        default:
            EmptyView()
        }
    }

    private func topItemTitle(from snapshot: TodayWidgetSnapshot) -> String {
        snapshot.sections
            .flatMap(\.items)
            .first?
            .title ?? "할 일이 없습니다"
    }
}
