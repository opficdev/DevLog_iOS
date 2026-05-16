//
//  TodoQuery.swift
//  DevLogDomain
//
//  Created by opfic on 2/21/26.
//

import Foundation

public struct TodoQuery: Equatable {
    public enum SortTarget: Equatable, Hashable {
        case createdAt
        case completedAt
        case deletedAt
        case updatedAt
        case dueDate

        public var fieldName: String {
            switch self {
            case .createdAt:
                return "createdAt"
            case .completedAt:
                return "completedAt"
            case .deletedAt:
                return "deletedAt"
            case .updatedAt:
                return "updatedAt"
            case .dueDate:
                return "dueDate"
            }
        }
    }

    public enum SortOrder: Equatable, Hashable {
        case latest
        case oldest

        public var isDescending: Bool {
            self == .latest
        }
    }

    public enum CompletionFilter: Equatable, Hashable {
        case all
        case incomplete
        case completed

        public var isCompletedValue: Bool? {
            switch self {
            case .all:
                return nil
            case .incomplete:
                return false
            case .completed:
                return true
            }
        }
    }

    public enum DueDateFilter: Equatable, Hashable {
        case all
        case withDueDate
        case withoutDueDate
    }

    public var category: TodoCategory?
    public var keyword: String?
    public var isPinned: Bool?
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
        category: TodoCategory? = nil,
        keyword: String? = nil,
        isPinned: Bool? = nil,
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
        self.category = category
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
