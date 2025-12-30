//
//  TodoManageViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/30/25.
//

import Foundation
import OrderedCollections

final class TodoManageViewModel: Store {
    struct State {
        var todoKinds = TodoKind.allCases
        var selectedTodoKinds = OrderedSet<TodoKind>()
    }

    enum Action {
        case moveItem(from: IndexSet, target: Int)
        case tapItem(_ item: TodoKind)
    }

    enum SideEffect { }

    @Published private(set) var state = State()

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .moveItem(let from, let target):
            state.selectedTodoKinds.elements.move(fromOffsets: from, toOffset: target)
        case .tapItem(let item):
            if state.selectedTodoKinds.contains(item) {
                state.selectedTodoKinds.remove(item)
            } else {
                state.selectedTodoKinds.append(item)
            }
        }
        return []
    }
}

extension TodoManageViewModel {
    func contains(_ kind: TodoKind) -> Bool {
        return state.selectedTodoKinds.contains(kind)
    }
}
