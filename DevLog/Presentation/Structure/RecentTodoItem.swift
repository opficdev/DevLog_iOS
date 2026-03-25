//
//  RecentTodoItem.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation

struct RecentTodoItem: Identifiable, Hashable {
    let id: String
    let number: Int?
    let title: String
    let isPinned: Bool
    let updatedAt: Date
    let tags: [String]
    let kind: TodoKind

    init(from todo: Todo) {
        self.id = todo.id
        self.number = todo.number
        self.title = todo.title
        self.isPinned = todo.isPinned
        self.updatedAt = todo.updatedAt
        self.tags = todo.tags
        self.kind = todo.kind
    }
}
