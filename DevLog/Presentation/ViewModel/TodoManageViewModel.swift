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
        var category: UserTodoCategory?
        var showSheet: Bool = false
        var showAlert: Bool = false
    }

    enum Action {
        case tapAddUserCategory
        case moveItem(from: IndexSet, target: Int)
        case tapItem(_ item: TodoCategory)
        case tapEditUserCategory(TodoCategoryPreference)
        case tapDeleteUserCategory(TodoCategoryPreference)
        case confirmDeleteUserCategory
        case setShowSheet(Bool)
        case setShowAlert(Bool)
        case setCategoryName(String)
        case setCategoryColor(Color)
        case saveUserCategory
    }

    enum SideEffect { }

    private(set) var state: State

    var isEditing: Bool {
        guard let userTodoCategory = state.category else {
            return false
        }

        return state.preferences.contains { preference in
            guard case .user(let currentCategory) = preference.category else {
                return false
            }

            return currentCategory.id == userTodoCategory.id
        }
    }

    var navigationTitle: String {
        isEditing ? "카테고리 수정" : "카테고리 추가"
    }

    var submitTitle: String {
        isEditing ? "저장" : "추가"
    }

    var placerholder: String {
        state.category?.name ?? "이름"
    }

    var categoryNameCountText: String {
        "\((state.category?.name ?? "").count)/\(20)"
    }

    var canSubmitUserCategory: Bool {
        let trimmedCategoryName = state.category?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
        case .tapAddUserCategory:
            state.category = UserTodoCategory(
                id: UUID().uuidString.lowercased(),
                name: "",
                colorHex: "#0A84FF"
            )
            state.showSheet = true
        case .moveItem(let from, let target):
            state.preferences.move(fromOffsets: from, toOffset: target)
        case .tapItem(let item):
            if let index = state.preferences.firstIndex(where: { $0.category == item }) {
                state.preferences[index].isVisible.toggle()
            }
        case .tapEditUserCategory(let preference):
            guard case .user(let userTodoCategory) = preference.category else {
                break
            }

            state.category = userTodoCategory
            state.showSheet = true
        case .tapDeleteUserCategory(let preference):
            guard case .user(let userTodoCategory) = preference.category else {
                break
            }

            state.category = userTodoCategory
            state.showAlert = true
        case .confirmDeleteUserCategory:
            guard let userTodoCategory = state.category else {
                break
            }

            if let index = state.preferences.firstIndex(where: {
                guard case .user(let currentCategory) = $0.category else {
                    return false
                }

                return currentCategory.id == userTodoCategory.id
            }) {
                state.preferences.remove(at: index)
            }
            state.showAlert = false
            state.category = nil
        case .setShowSheet(let isPresented):
            state.showSheet = isPresented
            if !isPresented {
                state.category = nil
            }
        case .setShowAlert(let isPresented):
            state.showAlert = isPresented
            if !isPresented {
                state.category = nil
            }
        case .setCategoryName(let name):
            guard var category = state.category else { break }
            category.name = String(name.prefix(20))
            state.category = category
        case .setCategoryColor(let color):
            guard var category = state.category else { break }

            category.colorHex = color.hexString ?? "#0A84FF"
            state.category = category
        case .saveUserCategory:
            guard let category = state.category else { break }

            let name = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let updatedCategory = UserTodoCategory(
                id: category.id,
                name: name,
                colorHex: category.colorHex
            )

            if let index = state.preferences.firstIndex(where: {
                guard case .user(let currentCategory) = $0.category else {
                    return false
                }

                return currentCategory.id == updatedCategory.id
            }) {
                let preference = state.preferences[index]
                state.preferences[index] = TodoCategoryPreference(
                    category: .user(updatedCategory),
                    isVisible: preference.isVisible
                )
            } else {
                state.preferences.append(
                    TodoCategoryPreference(
                        category: .user(updatedCategory),
                        isVisible: true
                    )
                )
            }

            state.showSheet = false
            state.category = nil
        }

        if self.state != state { self.state = state }
        return []
    }
}
