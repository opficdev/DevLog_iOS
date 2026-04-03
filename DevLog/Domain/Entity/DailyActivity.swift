//
//  DailyActivity.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

import Foundation

enum ActivityKind: String, Hashable {
    case created
    case completed
    case deleted
}

struct DailyActivity: Hashable {
    let dayKey: String
    let createdCount: Int
    let completedCount: Int
    let deletedCount: Int
}

struct DailyActivityEvent: Hashable {
    let id: String
    let dayKey: String
    let kind: ActivityKind
    let occurredAt: Date
    let todoId: String
    let todoTitle: String
    let todoNumber: Int
    let todoCategoryID: String
    let isDeleted: Bool
}
