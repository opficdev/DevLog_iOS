//
//  TodayTodoWidgetEntryView.swift
//  DevLogWidgetExtension
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
            Text("widget_today_title")
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

                if let item = displayedItems(from: snapshot).first {
                    todoRow(item)
                } else {
                    Text("widget_today_empty_message")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        case .systemMedium:
            let items = displayedItems(from: snapshot)
            VStack(alignment: .leading, spacing: 6) {
                if items.isEmpty {
                    Text("widget_today_empty_message")
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items, id: \.id) { item in
                        todoRow(item, lineLimit: 1)
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
        case .systemSmall:
            GeometryReader { proxy in
                VStack(alignment: .leading, spacing: 4) {
                    placeholderTodoCount()
                    placeholderTodoRow(width: placeholderTodoRowWidth(in: proxy.size.width, at: 0))
                }
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .systemMedium:
            GeometryReader { proxy in
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        placeholderTodoRow(width: placeholderTodoRowWidth(in: proxy.size.width, at: index))
                    }
                }
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            EmptyView()
        }
    }

    private func displayedItems(from snapshot: TodayWidgetSnapshot) -> [WidgetTodayTodoSnapshot] {
        Array(snapshot.items.prefix(3))
    }

    private func todoRow(_ item: WidgetTodayTodoSnapshot, lineLimit: Int? = nil) -> some View {
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
                .lineLimit(lineLimit)
        }
    }

    private func placeholderTodoCount() -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.secondary.opacity(0.18))
            .frame(width: 22, height: 28)
    }

    private func placeholderTodoRow(width: CGFloat) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.18))
                .frame(width: 22, height: 8)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.18))
                .frame(width: width, height: 8)
        }
    }

    private func placeholderTodoRowWidth(in availableWidth: CGFloat, at index: Int) -> CGFloat {
        let titleAreaWidth = max(availableWidth - 28, 0)

        switch index {
        case 0:
            return titleAreaWidth * 2 / 3
        case 1:
            return titleAreaWidth / 2
        default:
            return titleAreaWidth * 3 / 5
        }
    }
}
