//
//  TodoDTO.swift
//  DevLogData
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

public struct WidgetTodoSnapshot: Equatable {
    public let id: String
    public let number: Int?
    public let title: String
    public let isPinned: Bool
    public let createdAt: Date
    public let completedAt: Date?
    public let deletedAt: Date?
    public let dueDate: Date?

    public init(
        id: String,
        number: Int?,
        title: String,
        isPinned: Bool,
        createdAt: Date,
        completedAt: Date?,
        deletedAt: Date?,
        dueDate: Date?
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.dueDate = dueDate
    }
}
