//
//  PinnedTodoItem.swift
//  DevLog
//
//  Created by 최윤진 on 2/17/26.
//

import Foundation

struct PinnedTodoItem: Identifiable, Hashable {
    let id: String
    let title: String
    let dueDate: Date?
    let kind: TodoKind

    init(from todo: Todo) {
        self.id = todo.id
        self.title = todo.title
        self.dueDate = todo.dueDate
        self.kind = todo.kind
    }
}
