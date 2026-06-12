//
//  TodoQuery+Presentation.swift
//  DevLogPresentation
//
//  Created by opfic on 6/12/26.
//

import DevLogCore
import Foundation

extension TodoQuery.SortTarget {
    var title: String {
        switch self {
        case .createdAt:
            return String(localized: "todo_sort_created")
        case .completedAt:
            return String(localized: "profile_activity_completed")
        case .deletedAt:
            return String(localized: "profile_activity_deleted")
        case .updatedAt:
            return String(localized: "todo_sort_updated")
        case .dueDate:
            return String(localized: "todo_sort_due_date")
        }
    }
}

extension TodoQuery.SortOrder {
    var title: String {
        switch self {
        case .latest:
            return String(localized: "todo_sort_latest")
        case .oldest:
            return String(localized: "todo_sort_oldest")
        }
    }
}

extension TodoQuery.CompletionFilter {
    var title: String {
        switch self {
        case .all:
            return String(localized: "todo_completion_all")
        case .incomplete:
            return String(localized: "todo_completion_incomplete")
        case .completed:
            return String(localized: "todo_completion_completed")
        }
    }
}
