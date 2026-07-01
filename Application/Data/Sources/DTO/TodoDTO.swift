//
//  TodoDTO.swift
//  Data
//
//  Created by 최윤진 on 12/14/25.
//

import Foundation

public struct TodoRequest: Encodable {
    public let id: String
    public let isPinned: Bool
    public let isCompleted: Bool
    public let isChecked: Bool
    public let title: String
    public let content: String
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?
    public let deletedAt: Date?
    public let dueDate: Date?
    public let tags: [String]
    public let category: String

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
        deletedAt: Date?,
        dueDate: Date?,
        tags: [String],
        category: String
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
        self.deletedAt = deletedAt
        self.dueDate = dueDate
        self.tags = tags
        self.category = category
    }
}

public struct TodoResponse {
    public let id: String
    public let isPinned: Bool
    public let isCompleted: Bool
    public let isChecked: Bool
    public let number: Int
    public let title: String
    public let content: String
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?
    public let deletedAt: Date?
    public let dueDate: Date?
    public let tags: [String]
    public let category: TodoCategoryResponse

    public init(
        id: String,
        isPinned: Bool,
        isCompleted: Bool,
        isChecked: Bool,
        number: Int,
        title: String,
        content: String,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date?,
        deletedAt: Date?,
        dueDate: Date?,
        tags: [String],
        category: TodoCategoryResponse
    ) {
        self.id = id
        self.isPinned = isPinned
        self.isCompleted = isCompleted
        self.isChecked = isChecked
        self.number = number
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.dueDate = dueDate
        self.tags = tags
        self.category = category
    }
}
