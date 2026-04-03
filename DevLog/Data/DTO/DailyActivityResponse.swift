//
//  DailyActivityResponse.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

import Foundation

struct DailyActivityResponse {
    let dayKey: String
    let createdCount: Int
    let completedCount: Int
    let deletedCount: Int
}

struct DailyActivityEventResponse {
    let id: String
    let dayKey: String
    let kind: String
    let occurredAt: Date
    let todoId: String
    let todoTitle: String
    let todoNumber: Int
    let todoCategoryID: String
}
