//
//  TodayTodoWidgetConfigurationIntent.swift
//  WidgetExtension
//
//  Created by opfic on 4/15/26.
//

import AppIntents
import WidgetKit

struct TodayTodoWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget_today_title"
    static var description = IntentDescription("widget_today_description")
}
