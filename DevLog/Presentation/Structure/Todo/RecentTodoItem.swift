//
//  RecentTodoItem.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation

struct RecentTodoItem: Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    let isPinned: Bool
    let updatedAt: Date
    let tags: [String]
    var category: TodoCategory

    init?(from todo: Todo) {
        guard let number = todo.number else { return nil }
        self.id = todo.id
        self.number = number
        self.title = todo.title
        self.isPinned = todo.isPinned
        self.updatedAt = todo.updatedAt
        self.tags = todo.tags
        self.category = todo.category
    }
}
