//
//  TodayWidgetSnapshot.swift
//  WidgetExtension
//
//  Created by opfic on 4/17/26.
//

import Foundation

struct TodayWidgetSnapshot: Decodable, Equatable {
    let generatedAt: Date
    let totalCount: Int
    let focusedCount: Int
    let overdueCount: Int
    let dueSoonCount: Int
    let items: [WidgetTodayTodoSnapshot]
}

struct WidgetTodayTodoSnapshot: Decodable, Equatable {
    let id: String
    let number: Int
    let title: String
    let isPinned: Bool
    let dueDate: Date?
}
