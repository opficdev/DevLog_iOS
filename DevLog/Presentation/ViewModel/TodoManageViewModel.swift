//
//  TodoManageViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/30/25.
//

import Foundation

final class TodoManageViewModel: Store {
    struct State {
        var todoKindPreferences: [TodoKindPreference]
    }

    enum Action {
        case moveItem(from: IndexSet, target: Int)
        case tapItem(_ item: TodoKind)
    }

    enum SideEffect { }

    @Published private(set) var state: State

    init(_ todoKindPreferences: [TodoKindPreference]) {
        self.state = State(todoKindPreferences: todoKindPreferences)
    }

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .moveItem(let from, let target):
            state.todoKindPreferences.move(fromOffsets: from, toOffset: target)
        case .tapItem(let item):
            if let index = state.todoKindPreferences.firstIndex(where: { $0.kind == item }) {
                state.todoKindPreferences[index].isVisible.toggle()
            }
        }
        return []
    }
}
