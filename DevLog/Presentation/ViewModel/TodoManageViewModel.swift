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
        var preferences: [TodoCategoryPreference]
        var showSheet: Bool = false
        var showAlert: Bool = false
        var deletingPreference: TodoCategoryPreference?
        var categoryName: String = ""
        var categoryColor: Color = .blue
    }

    enum Action {
        case moveItem(from: IndexSet, target: Int)
        case tapItem(_ item: TodoCategory)
        case tapDeleteUserCategory(TodoCategoryPreference)
        case confirmDeleteUserCategory
        case setShowSheet(Bool)
        case setShowAlert(Bool)
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

    init(_ preferences: [TodoCategoryPreference]) {
        self.state = State(preferences: preferences)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .moveItem(let from, let target):
            state.preferences.move(fromOffsets: from, toOffset: target)
        case .tapItem(let item):
            if let index = state.preferences.firstIndex(where: { $0.category == item }) {
                state.preferences[index].isVisible.toggle()
            }
        case .tapDeleteUserCategory(let preference):
            state.deletingPreference = preference
            state.showAlert = true
        case .confirmDeleteUserCategory:
            guard let preference = state.deletingPreference else {
                break
            }

            if let index = state.preferences.firstIndex(where: {
                $0 == preference
            }) {
                state.preferences.remove(at: index)
            }
            state.showAlert = false
            state.deletingPreference = nil
        case .setShowSheet(let isPresented):
            state.showSheet = isPresented
            if !isPresented {
                state.categoryName = ""
                state.categoryColor = .blue
            }
        case .setShowAlert(let isPresented):
            state.showAlert = isPresented
            if !isPresented {
                state.deletingPreference = nil
            }
        case .setCategoryName(let name):
            state.categoryName = name
        case .setCategoryColor(let color):
            state.categoryColor = color
        case .addUserCategory:
            let trimmedCategoryName = state.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            if let colorHex = state.categoryColor.hexString {
                state.preferences.append(
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
            state.showSheet = false
            state.categoryName = ""
            state.categoryColor = .blue
        }

        if self.state != state { self.state = state }
        return []
    }
}
