//
//  TodoDraft.swift
//  DevLogDomain
//
//  Created by opfic on 6/2/26.
//

import Foundation

public struct TodoDraft: Hashable {
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
}
