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
        let kind: TodoKind
        var showEditor: Bool = false
        var showAlert: Bool = false
        var alertMessage: String = ""
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
        case tapTogglePinned(Todo)
        case swipeTodo(Todo)
        case tapFilterOption(FilterOption)
        case upsertTodo(Todo)

        // Binding
        case openEditor
        case closeEditor
        case closeAlert
        case setScope(TodoScope)
        case setSearchText(String)

        // Call from run
        case didFetchTodos([Todo])
        case didLoading(Bool)
        case didShowAlert(String)
        case didTogglePinned(Todo)
    }

    enum SideEffect {
        case fetchTodos
        case upsertTodo(Todo)
        case togglePinned(Todo)
        case swipeTodo(Todo)
    }

    private let fetchTodosByKindUseCase: FetchTodosByKindUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    @Published private(set) var state: State

    init(
        fetchTodosByKindUseCase: FetchTodosByKindUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        kind: TodoKind
    ) {
        self.fetchTodosByKindUseCase = fetchTodosByKindUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.state = State(kind: kind)
    }

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .onAppear, .refresh:
            return [.fetchTodos]
        case .tapTogglePinned(let todo):
            return [.togglePinned(todo)]
        case .swipeTodo(let todo):
            return [.swipeTodo(todo)]
        case .tapFilterOption(let option):
            state.filterOption = option
        case .upsertTodo(let todo):
            return [.upsertTodo(todo)]
        case .openEditor:
            state.showEditor = true
        case .closeEditor:
            state.showEditor = false
        case .closeAlert:
            state.showAlert = false
        case .setScope(let scope):
            state.scope = scope
        case .setSearchText(let text):
            state.searchText = text
        case .didFetchTodos(let todos):
            state.todos = todos
        case .didLoading(let value):
            state.isLoading = value
        case .didShowAlert(let message):
            state.alertMessage = message
            state.showAlert = true
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
            Task {
                do {
                    defer { send(.didLoading(false)) }
                    send(.didLoading(true))
                    let todos = try await fetchTodosByKindUseCase.execute(state.kind)
                    send(.didFetchTodos(todos))
                } catch {
                    send(.didShowAlert(error.localizedDescription))
                }
            }
        case .upsertTodo(let todo):
            Task {
                do {
                    defer { send(.didLoading(false)) }
                    send(.didLoading(true))
                    try await upsertTodoUseCase.execute(todo)
                    send(.refresh)
                } catch {
                    send(.didShowAlert(error.localizedDescription))
                }
            }
        case .togglePinned(let todo):
            Task {
                do {
                    defer { send(.didLoading(false)) }
                    send(.didLoading(true))
                    var todo = todo
                    todo.isPinned.toggle()
                    try await upsertTodoUseCase.execute(todo)
                    send(.didTogglePinned(todo))
                } catch {
                    send(.didShowAlert(error.localizedDescription))
                }
            }
        case .swipeTodo(let todo):
            break
        }
    }
}
