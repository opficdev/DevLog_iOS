//
//  TodoQuery.swift
//  DevLog
//
//  Created by opfic on 2/21/26.
//

import Foundation

struct TodoQuery: Equatable {
    enum SortTarget: Equatable, Hashable {
        case createdAt
        case completedAt
        case deletedAt
        case updatedAt
        case dueDate

        var fieldName: String {
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

    enum SortOrder: Equatable, Hashable {
        case latest
        case oldest

        var isDescending: Bool {
            self == .latest
        }
    }

    enum CompletionFilter: Equatable, Hashable {
        case all
        case incomplete
        case completed

        var isCompletedValue: Bool? {
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

    enum DueDateFilter: Equatable, Hashable {
        case all
        case withDueDate
        case withoutDueDate
    }

    var category: TodoCategory?
    var keyword: String?
    var isPinned: Bool?
    var completionFilter: CompletionFilter
    var dueDateFilter: DueDateFilter
    var sortDateFrom: Date?
    var sortDateTo: Date?
    var includesDeleted: Bool
    var sortTarget: SortTarget
    var sortOrder: SortOrder
    var pageSize: Int
    var fetchAllPages: Bool

    init(
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
