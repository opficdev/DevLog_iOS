//
//  TodoCategory.swift
//  DevLogDomain
//
//  Created by opfic on 3/29/26.
//

import Foundation

public enum TodoCategory: Hashable {
    case system(SystemTodoCategory)
    case user(UserTodoCategory)

    public var storageValue: String {
        switch self {
        case .system(let category):
            return category.rawValue
        case .user(let category):
            return category.id
        }
    }
}
