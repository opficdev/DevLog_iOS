//
//  TodayWidgetSnapshot.swift
//  DevLogWidgetCore
//
//  Created by opfic on 4/17/26.
//

import Foundation

public struct TodayWidgetSnapshot: Codable, Equatable {
    let generatedAt: Date
    let totalCount: Int
    let focusedCount: Int
    let overdueCount: Int
    let dueSoonCount: Int
    let items: [WidgetTodayTodoSnapshot]
}

public struct WidgetTodayTodoSnapshot: Codable, Equatable {
    let id: String
    let number: Int
    let title: String
    let isPinned: Bool
    let dueDate: Date?
}
