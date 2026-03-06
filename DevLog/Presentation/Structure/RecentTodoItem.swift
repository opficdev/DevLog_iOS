//
//  RecentTodoItem.swift
//  DevLog
//
//  Created by Codex on 3/6/26.
//

import Foundation

struct RecentTodoItem: Identifiable, Hashable {
    let id: String
    let title: String
    let updatedAt: Date
    let kind: TodoKind

    init(from todo: Todo) {
        self.id = todo.id
        self.title = todo.title
        self.updatedAt = todo.updatedAt
        self.kind = todo.kind
    }
}
