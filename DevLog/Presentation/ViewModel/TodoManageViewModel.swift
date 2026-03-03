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
        var todoKindPreferences: [TodoKindPreference]
    }

    enum Action {
        case moveItem(from: IndexSet, target: Int)
        case tapItem(_ item: TodoKind)
    }

    enum SideEffect { }

    private(set) var state: State

    init(_ todoKindPreferences: [TodoKindPreference]) {
        self.state = State(todoKindPreferences: todoKindPreferences)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .moveItem(let from, let target):
            state.todoKindPreferences.move(fromOffsets: from, toOffset: target)
        case .tapItem(let item):
            if let index = state.todoKindPreferences.firstIndex(where: { $0.kind == item }) {
                state.todoKindPreferences[index].isVisible.toggle()
            }
        }

        if self.state != state { self.state = state }
        return []
    }
}
