//
//  TodoQuery.swift
//  Core
//
//  Created by opfic on 2/21/26.
//

import Foundation

public struct TodoQuery: Equatable, Sendable {
    public enum SortTarget: Equatable, Hashable, Sendable {
        case createdAt
        case completedAt
        case deletedAt
        case updatedAt
        case dueDate
    }

    public enum SortOrder: Equatable, Hashable, Sendable {
        case latest
        case oldest
    }

    public enum CompletionFilter: Equatable, Hashable, Sendable {
        case all
        case incomplete
        case completed
    }

    public enum DueDateFilter: Equatable, Hashable, Sendable {
        case all
        case withDueDate
        case withoutDueDate
    }

    public var categoryId: String?
    public var keyword: String?
    public var isPinned: Bool
    public var completionFilter: CompletionFilter
    public var dueDateFilter: DueDateFilter
    public var sortDateFrom: Date?
    public var sortDateTo: Date?
    public var includesDeleted: Bool
    public var sortTarget: SortTarget
    public var sortOrder: SortOrder
    public var pageSize: Int
    public var fetchAllPages: Bool

    public init(
        categoryId: String? = nil,
        keyword: String? = nil,
        isPinned: Bool = false,
        completionFilter: CompletionFilter = .all,
        dueDateFilter: DueDateFilter = .all,
        sortDateFrom: Date? = nil,
        sortDateTo: Date? = nil,
        includesDeleted: Bool = false,
        sortTarget: SortTarget = .createdAt,
        sortOrder: SortOrder = .latest,
        pageSize: Int = 20,
        fetchAllPages: Bool = false
    ) {
        self.categoryId = categoryId
        self.keyword = keyword
        self.isPinned = isPinned
        self.completionFilter = completionFilter
        self.dueDateFilter = dueDateFilter
        self.sortDateFrom = sortDateFrom
        self.sortDateTo = sortDateTo
        self.includesDeleted = includesDeleted
        self.sortTarget = sortTarget
        self.sortOrder = sortOrder
        self.pageSize = pageSize
        self.fetchAllPages = fetchAllPages
    }
}
