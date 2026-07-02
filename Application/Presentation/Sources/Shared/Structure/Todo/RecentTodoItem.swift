//
//  RecentTodoItem.swift
//  Presentation
//
//  Created by opfic on 3/6/26.
//

import Foundation
import Domain

public struct RecentTodoItem: Identifiable, Hashable {
    public let id: String
    public let number: Int
    public let title: String
    public let isPinned: Bool
    public let updatedAt: Date
    public let tags: [String]
    public var category: TodoCategory

    public init?(from todo: Todo) {
        self.id = todo.id
        self.number = todo.number
        self.title = todo.title
        self.isPinned = todo.isPinned
        self.updatedAt = todo.updatedAt
        self.tags = todo.tags
        self.category = todo.category
    }
}
