//
//  TodayTodoWidgetEntryView.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import WidgetKit

struct TodayTodoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today Todo")
                .font(.headline)

            Spacer()

            switch widgetFamily {
            case .systemSmall:
                Text("앱을 열어\nToday 위젯을 준비하세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .systemMedium, .systemLarge:
                WidgetPlaceholderCard(
                    title: "Today Todo",
                    message: "데이터 연결 전"
                )
                .frame(maxWidth: .infinity)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
