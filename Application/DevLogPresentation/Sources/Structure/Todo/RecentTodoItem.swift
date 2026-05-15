//
//  RecentTodoItem.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation
import DevLogDomain
import DevLogData

public struct RecentTodoItem: Identifiable, Hashable {
    public let id: String
    public let number: Int
    public let title: String
    public let isPinned: Bool
    public let updatedAt: Date
    public let tags: [String]
    public var category: TodoCategory

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
