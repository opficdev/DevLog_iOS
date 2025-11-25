//
//  TodoViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class TodoViewModel: Store {
    struct State {
        var todos: [Todo] = []
        var searchText: String = ""
        var kind: TodoKind
        var showEditor: Bool = false
        var showToast: Bool = false
        var toastMessage: String = ""
        var scope: TodoScope = .title
        var filterOption: FilterOption = .create
        var isLoading = false
    }

    enum FilterOption {
        case create, update, day, week, month, year
    }

    enum Action {
        // Modifier
        case onAppear, refresh

        // User
        case didTapTogglePinned(Todo)
        case didSwipeTodo(Todo)
        case didTapFilterOption(FilterOption)
        case upsertTodo(Todo)

        // Binding
        case openEditor
        case closeEditor
        case closeToast
        case setScope(TodoScope)
        case setSearchText(String)

        // Call from run
        case didFetchTodos([Todo])
        case didTogglePinned(Todo)
    }

    enum SideEffect {
        case fetchTodos
        case togglePinned(Todo)
    }

    @Published private(set) var state: State

    init(kind: TodoKind) {
        self.state = State(kind: kind)
    }

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .onAppear, .refresh:
            return [.fetchTodos]
        case .didTapTogglePinned(let todo):
            break
        case .didSwipeTodo(let todo):
            break
        case .didTapFilterOption(let option):
            state.filterOption = option
        case .upsertTodo(let todo):
//            Task {
//                let todo = Todo(
//                    title: title,
//                    content: content,
//                    tags: tags,
//                    dueDate: hasDueDate ? dueDate : nil,
//                    kind: todoVM.kind
//                )
//                await todoVM.upsertTodo(todo)
//                await todoVM.requestTodoList()
//            }
            break

        case .openEditor:
            state.showEditor = true
        case .closeEditor:
            state.showEditor = false
        case .closeToast:
            state.showToast = false
        case .setScope(let scope):
            state.scope = scope
        case .setSearchText(let text):
            state.searchText = text

        case .didFetchTodos(let todos):
            state.todos = todos
        case .didTogglePinned(let todo):
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.todos[index] = todo
            }
        }
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchTodos:
            break
        case .togglePinned(let todo):
            break
        }
    }
}
