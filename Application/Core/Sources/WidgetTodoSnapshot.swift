//
//  WidgetTodoSnapshot.swift
//  Core
//
//  Created by opfic on 5/18/26.
//

import Foundation

public struct WidgetTodoSnapshot: Equatable {
    public let id: String
    public let number: Int?
    public let title: String
    public let categoryID: String
    public let categoryColorHex: String?
    public let isPinned: Bool
    public let createdAt: Date
    public let completedAt: Date?
    public let deletedAt: Date?
    public let dueDate: Date?

    public init(
        id: String,
        number: Int?,
        title: String,
        categoryID: String,
        categoryColorHex: String?,
        isPinned: Bool,
        createdAt: Date,
        completedAt: Date?,
        deletedAt: Date?,
        dueDate: Date?
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.categoryID = categoryID
        self.categoryColorHex = categoryColorHex
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.dueDate = dueDate
    }
}
