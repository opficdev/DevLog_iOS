//
//  TodoQueryCursorMapper.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import FirebaseFirestore
import Core
import Data

enum TodoQueryCursorMapper {
    static func fieldName(for target: TodoQuery.SortTarget) -> String {
        switch target {
        case .createdAt:
            "createdAt"
        case .completedAt:
            "completedAt"
        case .deletedAt:
            "deletedAt"
        case .updatedAt:
            "updatedAt"
        case .dueDate:
            "dueDate"
        }
    }

    static func isDescending(_ order: TodoQuery.SortOrder) -> Bool {
        order == .latest
    }

    static func isCompletedValue(for filter: TodoQuery.CompletionFilter) -> Bool? {
        switch filter {
        case .all:
            nil
        case .incomplete:
            false
        case .completed:
            true
        }
    }

    static func makeValues(query: TodoQuery, cursor: TodoCursorDTO) -> [Any]? {
        let primaryValue: Any = cursor.primarySortDate.map { Timestamp(date: $0) } ?? NSNull()
        switch query.sortTarget {
        case .dueDate:
            guard let secondaryDate = cursor.secondarySortDate else { return nil }
            return [primaryValue, Timestamp(date: secondaryDate), cursor.documentID]
        case .createdAt, .completedAt, .deletedAt, .updatedAt:
            return [primaryValue, cursor.documentID]
        }
    }

    static func makeCursor(document: QueryDocumentSnapshot, query: TodoQuery) -> TodoCursorDTO? {
        let data = document.data()
        let fieldName = fieldName(for: query.sortTarget)
        let primarySortDate: Date?
        if let timestamp = data[fieldName] as? Timestamp {
            primarySortDate = timestamp.dateValue()
        } else if data[fieldName] is NSNull {
            primarySortDate = nil
        } else {
            return nil
        }

        let secondarySortDate: Date?
        switch query.sortTarget {
        case .dueDate:
            guard let updatedAt = data[TodoDocumentFieldKey.updatedAt.rawValue] as? Timestamp else {
                return nil
            }
            secondarySortDate = updatedAt.dateValue()
        case .createdAt, .completedAt, .deletedAt, .updatedAt:
            secondarySortDate = nil
        }

        return TodoCursorDTO(
            primarySortDate: primarySortDate,
            secondarySortDate: secondarySortDate,
            documentID: document.documentID
        )
    }
}
