//
//  TodoCategoryMapping.swift
//  DevLogData
//
//  Created by opfic on 5/16/26.
//

import DevLogDomain

extension TodoCategoryPreferenceResponse {
    static func fromDomain(_ preference: TodoCategoryPreference) -> Self {
        switch preference.category {
        case .system(let systemTodoCategory):
            return TodoCategoryPreferenceResponse(
                category: .system(systemTodoCategory.rawValue),
                isVisible: preference.isVisible
            )
        case .user(let userTodoCategory):
            return TodoCategoryPreferenceResponse(
                category: .user(
                    UserCategory(
                        id: userTodoCategory.id,
                        name: userTodoCategory.name,
                        colorHex: userTodoCategory.colorHex
                    )
                ),
                isVisible: preference.isVisible
            )
        }
    }

    func toDomain() -> TodoCategoryPreference? {
        switch category {
        case .system(let rawValue):
            guard let systemTodoCategory = SystemTodoCategory(rawValue: rawValue) else {
                return nil
            }

            return TodoCategoryPreference(
                category: .system(systemTodoCategory),
                isVisible: isVisible
            )
        case .user(let userCategory):
            return TodoCategoryPreference(
                category: .user(
                    UserTodoCategory(
                        id: userCategory.id,
                        name: userCategory.name,
                        colorHex: userCategory.colorHex
                    )
                ),
                isVisible: isVisible
            )
        }
    }
}

extension Array where Element == TodoCategoryPreferenceResponse {
    func toDomain() -> [TodoCategoryPreference] {
        let preferences = compactMap { $0.toDomain() }
        guard !preferences.isEmpty else {
            return defaultTodoCategoryPreferences()
        }

        return mergedTodoCategoryPreferences(preferences)
    }
}

private func defaultTodoCategoryPreferences() -> [TodoCategoryPreference] {
    SystemTodoCategory.allCases.map {
        TodoCategoryPreference(category: .system($0), isVisible: true)
    }
}

private func mergedTodoCategoryPreferences(
    _ preferences: [TodoCategoryPreference]
) -> [TodoCategoryPreference] {
    var mergedPreferences = preferences
    let existingSystemTodoCategories = Set<SystemTodoCategory>(
        preferences.compactMap { preference in
            guard case .system(let systemTodoCategory) = preference.category else {
                return nil
            }

            return systemTodoCategory
        }
    )

    for systemTodoCategory in SystemTodoCategory.allCases {
        if existingSystemTodoCategories.contains(systemTodoCategory) { continue }

        mergedPreferences.append(
            TodoCategoryPreference(
                category: .system(systemTodoCategory),
                isVisible: true
            )
        )
    }

    return mergedPreferences
}
