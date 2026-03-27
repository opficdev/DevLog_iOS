//
//  TodoManageViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/30/25.
//

import Foundation

@Observable
final class TodoManageViewModel: Store {
    struct State: Equatable {
        var todoCategoryPreferences: [TodoCategoryPreference]
    }

    enum Action {
        case moveItem(from: IndexSet, target: Int)
        case tapItem(_ item: TodoCategory)
    }

    enum SideEffect { }

    private(set) var state: State

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
        }

        if self.state != state { self.state = state }
        return []
    }
}
