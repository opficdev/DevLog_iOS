//
//  TodayTodoWidgetEntryView.swift
//  WidgetExtension
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import WidgetKit

struct TodayTodoWidgetEntryView: View {
    let entry: TodayTodoWidgetEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            if entry.requiresReinstallation {
                reinstallContent
            } else {
                switch widgetFamily {
                case .systemSmall:
                    smallContent
                case .systemMedium:
                    mediumContent
                default:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        Text("widget_today_title")
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var reinstallContent: some View {
        VStack(alignment: .leading) {
            header
            Spacer()
            Text("widget_today_reinstall_message")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(3)
            Spacer()
        }
    }

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: 8)

            if let snapshot = entry.snapshot {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(snapshot.totalCount)")
                        .font(.largeTitle.bold())
                    Text("widget_today_count_unit")
                        .font(.callout.weight(.semibold))
                }
                .foregroundStyle(Color.accent)
            } else {
                placeholder(width: 42, height: 30)
            }

            Spacer(minLength: 8)
            Divider()

            Group {
                if let snapshot = entry.snapshot {
                    if let item = displayedItems(from: snapshot).first {
                        todoRow(item)
                    } else {
                        Text("widget_today_empty_small")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                } else {
                    placeholderRow
                }
            }
            .padding(.top, 8)
        }
    }

    private var mediumContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Text(entry.date, format: .dateTime.month().day().weekday(.wide))
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 6)

            if let snapshot = entry.snapshot {
                let items = displayedItems(from: snapshot)
                if items.isEmpty {
                    Text("widget_today_empty_message")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            todoRow(item)
                            if index < items.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        placeholderRow
                    }
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 3) {
                Text("widget_today_open_all")
                Image(systemName: "chevron.right")
            }
            .font(.caption2)
            .foregroundStyle(Color.textSecondary)
            .lineLimit(1)
        }
    }

    private func displayedItems(from snapshot: TodayWidgetSnapshot) -> [WidgetTodayTodoSnapshot] {
        Array(snapshot.items.prefix(3))
    }

    private func todoRow(_ item: WidgetTodayTodoSnapshot) -> some View {
        let style = WidgetTodoCategoryStyle(
            categoryID: item.categoryID,
            colorHex: item.categoryColorHex
        )

        return HStack(spacing: 6) {
            Image(systemName: style.symbolName)
                .font(.caption2.bold())
                .foregroundStyle(style.color)
                .frame(width: 22, height: 22)
                .background(
                    style.color.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 7)
                )

            Text("#\(item.number)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.accent)

            Text(item.title)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
    }

    private var placeholderRow: some View {
        HStack(spacing: 6) {
            placeholder(width: 22, height: 22)
            placeholder(width: 22, height: 8)
            placeholder(width: 70, height: 8)
        }
        .frame(height: 24)
    }

    private func placeholder(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.textSecondary.opacity(0.18))
            .frame(width: width, height: height)
    }
}
