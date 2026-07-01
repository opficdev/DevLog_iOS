//
//  TodoDraft.swift
//  Domain
//
//  Created by opfic on 6/2/26.
//

import Foundation

public struct TodoDraft: Equatable {
    public var id: String
    public var isPinned: Bool
    public var isCompleted: Bool
    public var isChecked: Bool
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?
    public var dueDate: Date?
    public var tags: [String]
    public var category: TodoCategory

    public init(
        id: String,
        isPinned: Bool,
        isCompleted: Bool,
        isChecked: Bool,
        title: String,
        content: String,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date?,
        dueDate: Date?,
        tags: [String],
        category: TodoCategory
    ) {
        self.id = id
        self.isPinned = isPinned
        self.isCompleted = isCompleted
        self.isChecked = isChecked
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.tags = tags
        self.category = category
    }

    public init(todo: Todo) {
        self.id = todo.id
        self.isPinned = todo.isPinned
        self.isCompleted = todo.isCompleted
        self.isChecked = todo.isChecked
        self.title = todo.title
        self.content = todo.content
        self.createdAt = todo.createdAt
        self.updatedAt = todo.updatedAt
        self.completedAt = todo.completedAt
        self.dueDate = todo.dueDate
        self.tags = todo.tags
        self.category = todo.category
    }

    public static func == (lhs: TodoDraft, rhs: TodoDraft) -> Bool {
        lhs.id == rhs.id &&
        lhs.isPinned == rhs.isPinned &&
        lhs.isCompleted == rhs.isCompleted &&
        lhs.isChecked == rhs.isChecked &&
        lhs.title == rhs.title &&
        lhs.content == rhs.content &&
        lhs.completedAt == rhs.completedAt &&
        lhs.dueDate == rhs.dueDate &&
        lhs.tags == rhs.tags &&
        lhs.category == rhs.category
    }
}
