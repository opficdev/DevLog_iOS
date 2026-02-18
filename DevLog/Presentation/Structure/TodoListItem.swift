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

    private init(
        id: String,
        title: String,
        tags: [String],
        isPinned: Bool
    ) {
        self.id = id
        self.title = title
        self.tags = tags
        self.isPinned = isPinned
    }

    init(from todo: Todo) {
        self.init(
            id: todo.id,
            title: todo.title,
            tags: todo.tags,
            isPinned: todo.isPinned
        )
    }
}
