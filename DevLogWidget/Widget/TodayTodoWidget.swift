//
//  TodayTodoWidget.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import AppIntents
import WidgetKit

struct TodayTodoWidget: Widget {
    let kind = "TodayTodoWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TodayTodoWidgetConfigurationIntent.self,
            provider: TodayTodoWidgetProvider()
        ) { _ in
            TodayTodoWidgetEntryView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today Todo")
        .description("오늘 기준 Todo 목록을 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
