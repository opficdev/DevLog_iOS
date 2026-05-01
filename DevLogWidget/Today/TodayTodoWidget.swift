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
    let kind = WidgetKind.todayTodo

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TodayTodoWidgetConfigurationIntent.self,
            provider: TodayTodoWidgetProvider()
        ) { entry in
            TodayTodoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(WidgetDeepLink.todayTodoURL)
        }
        .description("widget_today_description")
        .configurationDisplayName("Today")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
