//
//  TodoManageViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/30/25.
//

import SwiftUI
import DevLogDomain
import DevLogData

@Observable
final class TodoManageViewModel: Store {
    struct State: Equatable {
        var preferences: [TodoCategoryItem]
        var category: TodoCategoryItem?
        var showSheet: Bool = false
        var showAlert: Bool = false
    }

    enum Action {
        case tapAddUserCategory
        case moveItem(from: IndexSet, target: Int)
        case tapItem(TodoCategoryItem)
        case tapEditUserCategory(TodoCategoryItem)
        case tapDeleteUserCategory(TodoCategoryItem)
        case confirmDeleteUserCategory
        case setShowSheet(Bool)
        case setShowAlert(Bool)
        case setCategoryName(String)
        case setCategoryColor(Color)
        case setRandomCategoryColor
        case saveUserCategory
    }

    enum SideEffect { }

    private(set) var state: State

    var isEditing: Bool {
        guard let categoryItem = state.category else {
            return false
        }

        return state.preferences.contains { $0.id == categoryItem.id }
    }

    var navigationTitle: String {
        isEditing
            ? String(localized: "todo_manage_edit_category_title")
            : String(localized: "todo_manage_add_category_title")
    }

    var submitTitle: String {
        isEditing
            ? String(localized: "todo_manage_save")
            : String(localized: "todo_add")
    }

    var placeholder: String {
        guard
            let item = state.category,
            case .user(let category) = item.category
        else {
            return String(localized: "todo_manage_name_placeholder")
        }

        return category.name
    }

    var categoryNameCountText: String {
        guard
            let item = state.category,
            case .user(let category) = item.category
        else {
            return "0/20"
        }

        return "\(category.name.count)/20"
    }

    var canSubmitUserCategory: Bool {
        guard
            let item = state.category,
            case .user(let category) = item.category
        else {
            return false
        }

        let name = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return false
        }

        if SystemTodoCategory.allCases.contains(where: {
            $0.rawValue.caseInsensitiveCompare(name) == .orderedSame
        }) {
            return false
        }

        if state.preferences.contains(where: { item in
            guard case .user(let userCategory) = item.category,
                  userCategory.id != category.id else {
                return false
            }

            return userCategory.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            return false
        }

        if let item = state.preferences.first(where: { $0.id == item.id }),
           case .user(let originalCategory) = item.category {
            let originalName = originalCategory.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if originalName == name && originalCategory.colorHex == category.colorHex {
                return false
            }
        }

        return true
    }

    init(_ preferences: [TodoCategoryItem]) {
        self.state = State(preferences: preferences)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .tapAddUserCategory:
            guard let randomHexValue = Color.randomValue.hexValue else {
                break
            }

            state.category = TodoCategoryItem(
                from: .user(
                    UserTodoCategory(
                        id: UUID().uuidString.lowercased(),
                        name: "",
                        colorHex: randomHexValue
                    )
                )
            )
            state.showSheet = true
        case .moveItem(let from, let target):
            state.preferences.move(fromOffsets: from, toOffset: target)
        case .tapItem(let item):
            if let index = state.preferences.firstIndex(where: { $0.id == item.id }) {
                state.preferences[index].isVisible.toggle()
            }
        case .tapEditUserCategory(let item):
            guard item.isUserCategory else {
                break
            }

            state.category = item
            state.showSheet = true
        case .tapDeleteUserCategory(let item):
            guard item.isUserCategory else {
                break
            }

            state.category = item
            state.showAlert = true
        case .confirmDeleteUserCategory:
            guard let categoryItem = state.category else {
                break
            }

            if let index = state.preferences.firstIndex(where: { $0.id == categoryItem.id }) {
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
            guard var item = state.category,
                  case .user(var category) = item.category else {
                break
            }

            category.name = String(name.prefix(20))
            item.category = .user(category)
            state.category = item
        case .setCategoryColor(let color):
            guard var item = state.category,
                  case .user(var category) = item.category,
                  let hexValue = color.hexValue else {
                break
            }

            category.colorHex = hexValue
            item.category = .user(category)
            state.category = item
        case .setRandomCategoryColor:
            guard var item = state.category,
                  case .user(var category) = item.category,
                  let randomHexValue = Color.randomValue.hexValue else {
                break
            }

            category.colorHex = randomHexValue
            item.category = .user(category)
            state.category = item
        case .saveUserCategory:
            guard var item = state.category,
                  case .user(let category) = item.category else {
                break
            }

            item.category = .user(
                UserTodoCategory(
                    id: category.id,
                    name: category.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    colorHex: category.colorHex
                )
            )

            if let index = state.preferences.firstIndex(where: { $0.id == item.id }) {
                item.isVisible = state.preferences[index].isVisible
                state.preferences[index] = item
            } else {
                state.preferences.append(item)
            }

            state.showSheet = false
            state.category = nil
        }

        if self.state != state { self.state = state }
        return []
    }
}
