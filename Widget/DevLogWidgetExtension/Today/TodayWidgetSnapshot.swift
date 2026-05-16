//
//  TodayWidgetSnapshot.swift
//  DevLogWidgetExtension
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
    let sections: [TodayWidgetSectionSnapshot]
}

struct TodayWidgetSectionSnapshot: Decodable, Equatable {
    let category: String
    let items: [WidgetTodoSnapshotItem]
}

struct WidgetTodoSnapshotItem: Decodable, Equatable {
    let id: String
    let number: Int
    let title: String
    let isPinned: Bool
    let dueDate: Date?
}
