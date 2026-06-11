//
//  CategoryManageFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/11/26.
//

import ComposableArchitecture
import DevLogDomain
import SwiftUI

@Reducer
struct CategoryManageFeature {
    @ObservableState
    struct State: Equatable {
        var preferences: [TodoCategoryItem]
        @Presents var categorySheet: CategorySheetState?
        @Presents var alert: AlertState<Action.Alert>?
    }

    @ObservableState
    struct CategorySheetState: Equatable {
        var category: UserTodoCategory
        var preferences: [TodoCategoryItem]

        var isEditing: Bool {
            preferences.contains { $0.id == category.id }
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
            category.name
        }
        var categoryNameCountText: String {
            "\(category.name.count)/20"
        }
        var canSubmitUserCategory: Bool {
            let name = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                return false
            }

            if SystemTodoCategory.allCases.contains(where: {
                $0.rawValue.caseInsensitiveCompare(name) == .orderedSame
            }) {
                return false
            }

            if preferences.contains(where: { item in
                guard case .user(let userCategory) = item.category, userCategory.id != category.id else {
                    return false
                }

                return userCategory.name.caseInsensitiveCompare(name) == .orderedSame
            }) {
                return false
            }

            if let item = preferences.first(where: { $0.id == category.id }) {
                if case .user(let originalCategory) = item.category {
                    let originalName = originalCategory.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if originalName == name && originalCategory.colorHex == category.colorHex {
                        return false
                    }
                }
            }

            return true
        }
        var todoCategoryItem: TodoCategoryItem {
            TodoCategoryItem(
                from: .user(
                    UserTodoCategory(
                        id: category.id,
                        name: category.name.trimmingCharacters(in: .whitespacesAndNewlines),
                        colorHex: category.colorHex
                    )
                )
            )
        }
    }

    enum Action {
        case alert(PresentationAction<Alert>)
        case categorySheet(PresentationAction<CategorySheet>)
        case tapAddUserCategory
        case moveItem(from: IndexSet, target: Int)
        case tapItem(TodoCategoryItem)
        case tapEditUserCategory(TodoCategoryItem)
        case tapDeleteUserCategory(TodoCategoryItem)
        case tapDoneButton

        enum Alert: Equatable {
            case confirmDeleteUserCategory(TodoCategoryItem)
        }

        enum CategorySheet: Equatable {
            case setCategoryName(String)
            case setCategoryColor(String)
            case tapCloseButton
            case tapRandomColorButton
            case tapSaveButton
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmDeleteUserCategory(let item))):
                if let index = state.preferences.firstIndex(where: { $0.id == item.id }) {
                    state.preferences.remove(at: index)
                }
            case .alert:
                break
            case .categorySheet(.dismiss):
                state.categorySheet = nil
            case .categorySheet(.presented(.tapCloseButton)):
                state.categorySheet = nil
            case .categorySheet(.presented(.setCategoryName(let name))):
                state.categorySheet?.category.name = String(name.prefix(20))
            case .categorySheet(.presented(.setCategoryColor(let colorHex))):
                state.categorySheet?.category.colorHex = colorHex
            case .categorySheet(.presented(.tapRandomColorButton)):
                if let randomHexValue = Color.randomValue.hexValue {
                    state.categorySheet?.category.colorHex = randomHexValue
                }
            case .categorySheet(.presented(.tapSaveButton)):
                if var item = state.categorySheet?.todoCategoryItem {
                    if let index = state.preferences.firstIndex(where: { $0.id == item.id }) {
                        item.isVisible = state.preferences[index].isVisible
                        state.preferences[index] = item
                    } else {
                        state.preferences.append(item)
                    }

                    state.categorySheet = nil
                }
            case .categorySheet:
                break
            case .tapAddUserCategory:
                if let randomHexValue = Color.randomValue.hexValue {
                    state.categorySheet = CategorySheetState(
                        category: UserTodoCategory(
                            id: UUID().uuidString.lowercased(),
                            name: "",
                            colorHex: randomHexValue
                        ),
                        preferences: state.preferences
                    )
                }
            case .moveItem(let from, let target):
                state.preferences.move(fromOffsets: from, toOffset: target)
            case .tapItem(let item):
                if let index = state.preferences.firstIndex(where: { $0.id == item.id }) {
                    state.preferences[index].isVisible.toggle()
                }
            case .tapEditUserCategory(let item):
                if item.isUserCategory, case .user(let category) = item.category {
                    state.categorySheet = CategorySheetState(
                        category: category,
                        preferences: state.preferences
                    )
                }
            case .tapDeleteUserCategory(let item):
                if item.isUserCategory {
                    state.alert = deleteAlertState(for: item)
                }
            case .tapDoneButton:
                break
            }
            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

private extension CategoryManageFeature {
    func deleteAlertState(for item: TodoCategoryItem) -> AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: "todo_manage_delete_category_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_cancel"))
            }
            ButtonState(role: .destructive, action: .confirmDeleteUserCategory(item)) {
                TextState(String(localized: "common_delete"))
            }
        } message: {
            TextState(String(localized: "todo_manage_delete_category_message"))
        }
    }
}
