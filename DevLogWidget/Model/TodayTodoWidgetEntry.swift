//
//  TodayTodoWidgetEntry.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import WidgetKit

struct TodayTodoWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TodayWidgetSnapshot?
}
