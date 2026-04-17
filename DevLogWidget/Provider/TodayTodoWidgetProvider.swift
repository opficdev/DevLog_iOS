//
//  TodayTodoWidgetProvider.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import AppIntents
import WidgetKit

struct TodayTodoWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = TodayTodoWidgetConfigurationIntent

    func placeholder(in context: Context) -> TodayTodoWidgetEntry {
        .init(date: .now)
    }

    func snapshot(
        for configuration: TodayTodoWidgetConfigurationIntent,
        in context: Context
    ) async -> TodayTodoWidgetEntry {
        .init(date: .now)
    }

    func timeline(
        for configuration: TodayTodoWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<TodayTodoWidgetEntry> {
        Timeline(
            entries: [.init(date: .now)],
            policy: .never
        )
    }
}
