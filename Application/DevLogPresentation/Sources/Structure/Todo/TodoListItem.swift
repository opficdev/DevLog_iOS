//
//  TodoListItem.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 2/17/26.
//

import Foundation
import DevLogDomain

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
        guard let number = todo.number else { return nil }
        self.id = todo.id
        self.number = number
        self.title = todo.title
        self.tags = todo.tags
        self.isPinned = todo.isPinned
        self.isCompleted = todo.isCompleted
        self.createdAt = todo.createdAt
        self.updatedAt = todo.updatedAt
    }
}
