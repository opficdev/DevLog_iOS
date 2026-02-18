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

    init(
        id: String,
        title: String,
        dueDate: Date?,
        kind: TodoKind
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.kind = kind
    }

    init(from todo: Todo) {
        self.init(
            id: todo.id,
            title: todo.title,
            dueDate: todo.dueDate,
            kind: todo.kind
        )
    }
}
