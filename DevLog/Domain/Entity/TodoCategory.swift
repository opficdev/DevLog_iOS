//
//  TodoCategory.swift
//  DevLog
//
//  Created by opfic on 3/29/26.
//

import Foundation

enum TodoCategory: Equatable {
    case system(SystemTodoCategory)
    case user(UserTodoCategory)

    var storageValue: String {
        switch self {
        case .system(let category):
            return category.rawValue
        case .user(let category):
            return category.name
        }
    }
}
