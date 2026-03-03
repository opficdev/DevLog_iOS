//
//  TodoListItem.swift
//  DevLog
//
//  Created by 최윤진 on 2/17/26.
//

import Foundation

struct TodoListItem: Identifiable, Hashable {
    let id: String
    let title: String
    let tags: [String]
    let isPinned: Bool
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date

    init(from todo: Todo) {
        self.id = todo.id
        self.title = todo.title
        self.tags = todo.tags
        self.isPinned = todo.isPinned
        self.isCompleted = todo.isCompleted
        self.createdAt = todo.createdAt
        self.updatedAt = todo.updatedAt
    }
}
