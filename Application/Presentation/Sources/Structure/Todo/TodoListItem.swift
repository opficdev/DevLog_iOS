//
//  TodoListItem.swift
//  Presentation
//
//  Created by 최윤진 on 2/17/26.
//

import Foundation
import Domain

public struct TodoListItem: Identifiable, Hashable {
    public let id: String
    public var isHidden = false
    public let number: Int
    public let title: String
    public let tags: [String]
    public let isPinned: Bool
    public let isCompleted: Bool
    public let createdAt: Date
    public let updatedAt: Date

    init?(from todo: Todo) {
        self.id = todo.id
        self.number = todo.number
        self.title = todo.title
        self.tags = todo.tags
        self.isPinned = todo.isPinned
        self.isCompleted = todo.isCompleted
        self.createdAt = todo.createdAt
        self.updatedAt = todo.updatedAt
    }
}
