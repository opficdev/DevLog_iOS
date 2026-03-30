//
//  TodoManageViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/30/25.
//

import SwiftUI

@Observable
final class TodoManageViewModel: Store {
    struct State: Equatable {
        var todoCategoryPreferences: [TodoCategoryPreference]
        var showAddCategorySheet: Bool = false
        var categoryName: String = ""
        var categoryColor: Color = .blue
    }

    enum Action {
        case moveItem(from: IndexSet, target: Int)
        case tapItem(_ item: TodoCategory)
        case deleteUserCategory(TodoCategoryPreference)
        case setShowAddCategorySheet(Bool)
        case setCategoryName(String)
        case setCategoryColor(Color)
        case addUserCategory
    }

    enum SideEffect { }

    private(set) var state: State
    var canAddUserCategory: Bool {
        let trimmedCategoryName = state.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCategoryName.isEmpty {
            return false
        }

        return !SystemTodoCategory.allCases.contains {
            $0.localizedName.localizedCaseInsensitiveCompare(trimmedCategoryName) == .orderedSame
        }
    }

    init(_ todoCategoryPreferences: [TodoCategoryPreference]) {
        self.state = State(todoCategoryPreferences: todoCategoryPreferences)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .moveItem(let from, let target):
            state.todoCategoryPreferences.move(fromOffsets: from, toOffset: target)
        case .tapItem(let item):
            if let index = state.todoCategoryPreferences.firstIndex(where: { $0.category == item }) {
                state.todoCategoryPreferences[index].isVisible.toggle()
            }
        case .deleteUserCategory(let preference):
            if let index = state.todoCategoryPreferences.firstIndex(where: { $0 == preference }) {
                state.todoCategoryPreferences.remove(at: index)
            }
        case .setShowAddCategorySheet(let isPresented):
            state.showAddCategorySheet = isPresented
            if !isPresented {
                state.categoryName = ""
                state.categoryColor = .blue
            }
        case .setCategoryName(let name):
            state.categoryName = name
        case .setCategoryColor(let color):
            state.categoryColor = color
        case .addUserCategory:
            let trimmedCategoryName = state.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            if let colorHex = state.categoryColor.hexString {
                state.todoCategoryPreferences.append(
                    TodoCategoryPreference(
                        category: .user(
                            UserTodoCategory(
                                name: trimmedCategoryName,
                                colorHex: colorHex
                            )
                        ),
                        isVisible: true
                    )
                )
            }
            state.showAddCategorySheet = false
            state.categoryName = ""
            state.categoryColor = .blue
        }

        if self.state != state { self.state = state }
        return []
    }
}
