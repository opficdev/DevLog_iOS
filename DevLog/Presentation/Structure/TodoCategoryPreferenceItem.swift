//
//  TodoCategoryPreferenceItem.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import SwiftUI

struct TodoCategoryPreferenceItem: Identifiable, Hashable {
    var category: TodoCategory
    var isVisible: Bool

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

    var id: String { category.storageValue }

    var todoCategory: TodoCategory { category }

    var preference: TodoCategoryPreference {
        TodoCategoryPreference(
            category: category,
            isVisible: isVisible
        )
    }

    var isUserCategory: Bool {
        if case .user = category {
            return true
        }

        return false
    }

    var symbolName: String {
        switch category {
        case .system(let systemTodoCategory):
            return SystemTodoCategoryItem(from: systemTodoCategory).symbolName
        case .user(let userTodoCategory):
            return UserTodoCategoryItem(from: userTodoCategory).symbolName
        }
    }

    var localizedName: String {
        switch category {
        case .system(let systemTodoCategory):
            return SystemTodoCategoryItem(from: systemTodoCategory).localizedName
        case .user(let userTodoCategory):
            return UserTodoCategoryItem(from: userTodoCategory).localizedName
        }
    }

    var color: Color {
        switch category {
        case .system(let systemTodoCategory):
            return SystemTodoCategoryItem(from: systemTodoCategory).color
        case .user(let userTodoCategory):
            return UserTodoCategoryItem(from: userTodoCategory).color
        }
    }

    static func == (lhs: TodoCategoryPreferenceItem, rhs: TodoCategoryPreferenceItem) -> Bool {
        lhs.category == rhs.category && lhs.isVisible == rhs.isVisible
    }

    func hash(into hasher: inout Hasher) {
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
