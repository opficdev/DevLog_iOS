//
//  TodayTodoItem.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation

struct TodayTodoItem: Identifiable, Hashable {
    let id: String
    let number: Int?
    let title: String
    let tags: [String]
    let isPinned: Bool
    let updatedAt: Date
    let dueDate: Date?
    let category: TodoCategory

    init(from todo: Todo) {
        self.id = todo.id
        self.number = todo.number
        self.title = todo.title
        self.tags = todo.tags
        self.isPinned = todo.isPinned
        self.updatedAt = todo.updatedAt
        self.dueDate = todo.dueDate
        self.category = todo.category
    }
}
