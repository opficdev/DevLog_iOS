//
//  TodayTodoWidgetConfigurationIntent.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import AppIntents
import WidgetKit

struct TodayTodoWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Today Todo"
    static var description = IntentDescription("오늘 기준 Todo 목록을 표시합니다.")
}
