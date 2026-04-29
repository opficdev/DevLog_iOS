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
        VStack(alignment: .leading) {
            Text("Today")
                .font(.headline)

            Spacer()

            if let snapshot = entry.snapshot {
                content(snapshot)
            } else {
                emptyState
            }

            Spacer()
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
        case .systemMedium:
            let items = displayedItems(from: snapshot)
            VStack(alignment: .leading, spacing: 6) {
                if items.isEmpty {
                    Text("오늘은 할 일이 없어요.\n잠시 휴식을 취해보세요!")
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items, id: \.id) { item in
                        todoRow(item)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch widgetFamily {
        case .systemSmall, .systemMedium:
            WidgetPlaceholderCard(message: "앱을 열어\nToday 위젯을 준비하세요")
                .frame(maxWidth: .infinity)
        default:
            EmptyView()
        }
    }

    private func topItemTitle(from snapshot: TodayWidgetSnapshot) -> String {
        snapshot.sections
            .flatMap(\.items)
            .first?
            .title ?? "오늘은 할 일이 없어요.\n잠시 휴식을 취해보세요!"
    }

    private func displayedItems(from snapshot: TodayWidgetSnapshot) -> [WidgetTodoSnapshotItem] {
        Array(snapshot
            .sections
            .flatMap(\.items)
            .prefix(3))
    }

    private func todoRow(_ item: WidgetTodoSnapshotItem) -> some View {
        HStack(spacing: 6) {
            Text("#\(item.number)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if item.isPinned {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Text(item.title)
                .font(.caption)
                .lineLimit(1)
        }
    }
}
