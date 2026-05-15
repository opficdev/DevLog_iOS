//
//  TodoCategoryItem.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import SwiftUI
import DevLogDomain
import DevLogData

public struct TodoCategoryItem: Identifiable, Hashable {
    public var category: TodoCategory
    public var isVisible: Bool

    init(from preference: TodoCategoryPreference) {
        self.category = preference.category
        self.isVisible = preference.isVisible
    }

    init(
        from category: TodoCategory,
        isVisible: Bool = true
    ) {
        self.category = category
        self.isVisible = isVisible
    }

    public var id: String { category.storageValue }

    public var todoCategory: TodoCategory { category }

    public var preference: TodoCategoryPreference {
        TodoCategoryPreference(
            category: category,
            isVisible: isVisible
        )
    }

    public var isUserCategory: Bool {
        if case .user = category {
            return true
        }

        return false
    }

    public var symbolName: String {
        switch category {
        case .system(let systemTodoCategory):
            return SystemTodoCategoryItem(from: systemTodoCategory).symbolName
        case .user(let userTodoCategory):
            return UserTodoCategoryItem(from: userTodoCategory).symbolName
        }
    }

    public var localizedName: String {
        switch category {
        case .system(let systemTodoCategory):
            return SystemTodoCategoryItem(from: systemTodoCategory).localizedName
        case .user(let userTodoCategory):
            return UserTodoCategoryItem(from: userTodoCategory).localizedName
        }
    }

    public var color: Color {
        switch category {
        case .system(let systemTodoCategory):
            return Color(SystemTodoCategoryItem(from: systemTodoCategory).color)
        case .user(let userTodoCategory):
            return UserTodoCategoryItem(from: userTodoCategory).color
        }
    }

    public static func == (lhs: TodoCategoryItem, rhs: TodoCategoryItem) -> Bool {
        lhs.category == rhs.category && lhs.isVisible == rhs.isVisible
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)

        switch category {
        case .system(let systemTodoCategory):
            hasher.combine(systemTodoCategory.rawValue)
        case .user(let userTodoCategory):
            hasher.combine(userTodoCategory.name)
            hasher.combine(userTodoCategory.colorHex)
        }

        hasher.combine(isVisible)
    }
}
