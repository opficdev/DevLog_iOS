//
//  TodayWidgetSnapshot.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation
import DevLogDomain
import DevLogData

public struct TodayWidgetSnapshot: Codable, Equatable {
    let generatedAt: Date
    let totalCount: Int
    let focusedCount: Int
    let overdueCount: Int
    let dueSoonCount: Int
    let sections: [TodayWidgetSectionSnapshot]
}

public struct TodayWidgetSectionSnapshot: Codable, Equatable {
    let category: String
    let items: [WidgetTodoSnapshotItem]
}

public struct WidgetTodoSnapshotItem: Codable, Equatable {
    let id: String
    let number: Int
    let title: String
    let isPinned: Bool
    let dueDate: Date?
}
