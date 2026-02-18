//
//  TodoListViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class TodoListViewModel: Store {
    struct State {
        var todos: [TodoListItem] = []
        var searchText: String = ""
        let kind: TodoKind
        var showEditor: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var scope: TodoScope = .title
        var filterOption: FilterOption = .create
        var isLoading: Bool = false
        var showToast: Bool = false
        var toastMessage: String = ""
        var pendingTask: (TodoListItem, Int)?
    }

    enum FilterOption {
        case create, update, day, week, month, year
    }

    enum Action {
        // User
        case refresh
        case setAlert(Bool)
        case setShowEditor(Bool)
        case swipeTodo(TodoListItem)
        case tapFilterOption(FilterOption)
        case tapTogglePinned(TodoListItem)
        case undoDelete

        // View
        case confirmDelete
        case onAppear
        case setScope(TodoScope)
        case setSearchText(String)
        case setToast(isPresented: Bool)
        case upsertTodo(Todo)

        // Run
        case didTogglePinned(TodoListItem)
        case setLoading(Bool)
        case setTodos([TodoListItem])
    }

    enum SideEffect {
        case fetch
        case upsert(Todo)
        case delete(String)
        case togglePinned(TodoListItem)
    }

    private let fetchTodosByKindUseCase: FetchTodosByKindUseCase
    private let fetchTodoByIDUseCase: FetchTodoByIDUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    @Published private(set) var state: State

    init(
        fetchTodosByKindUseCase: FetchTodosByKindUseCase,
        fetchTodoByIDUseCase: FetchTodoByIDUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        deleteTodoUseCase: DeleteTodoUseCase,
        kind: TodoKind
    ) {
        self.fetchTodosByKindUseCase = fetchTodosByKindUseCase
        self.fetchTodoByIDUseCase = fetchTodoByIDUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.state = State(kind: kind)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .refresh, .setAlert, .setShowEditor, .swipeTodo, .tapFilterOption, .tapTogglePinned, .undoDelete:
            effects = reduceByUser(action, state: &state)

        case .confirmDelete, .onAppear, .setScope, .setSearchText, .setToast, .upsertTodo:
            effects = reduceByView(action, state: &state)

        case .didTogglePinned, .setLoading, .setTodos:
            effects = reduceByRun(action, state: &state)
        }

        self.state = state
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetch:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let todos = try await fetchTodosByKindUseCase.execute(state.kind)
                    send(.setTodos(todos.map { TodoListItem(from: $0) }))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .upsert(let item):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    try await upsertTodoUseCase.execute(item)
                    send(.refresh)
                } catch {
                    send(.setAlert(true))
                }
            }
        case .togglePinned(let item):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    var todo = try await fetchTodoByIDUseCase.execute(item.id)
                    todo.isPinned.toggle()
                    try await upsertTodoUseCase.execute(todo)
                    send(.didTogglePinned(TodoListItem(from: todo)))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .delete(let todoID):
            Task {
                do {
                    try await deleteTodoUseCase.execute(todoID)
                } catch {
                    send(.setAlert(true))
                }
            }
        }
    }
}

// MARK: - Reduce Methods
private extension TodoListViewModel {
    func reduceByUser(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .refresh:
            return [.fetch]
        case .setAlert(let value):
            setAlert(&state, isPresented: value)
        case .setShowEditor(let value):
            state.showEditor = value
        case .swipeTodo(let todo):
            guard let index = state.todos.firstIndex(where: { $0.id == todo.id }) else {
                return []
            }
            state.pendingTask = (todo, index)
            state.todos.remove(at: index)
            setToast(&state, isPresented: true)
        case .tapFilterOption(let option):
            state.filterOption = option
        case .tapTogglePinned(let todo):
            return [.togglePinned(todo)]
        case .undoDelete:
            guard let (todo, index) = state.pendingTask else { return [] }
            state.todos.insert(todo, at: index)
            state.pendingTask = nil
        default:
            break
        }
        return []
    }

    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .confirmDelete:
            guard let (item, _) = state.pendingTask else {
                return []
            }
            return [.delete(item.id)]
        case .onAppear:
            return [.fetch]
        case .setScope(let scope):
            state.scope = scope
        case .setSearchText(let text):
            state.searchText = text
        case .setToast(let isPresented):
            setToast(&state, isPresented: isPresented)
        case .upsertTodo(let todo):
            return [.upsert(todo)]
        default:
            break
        }
        return []
    }

    func reduceByRun(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .didTogglePinned(let todo):
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.todos[index] = todo
            }
        case .setLoading(let value):
            state.isLoading = value
        case .setTodos(let todos):
            state.todos = todos
        default:
            break
        }
        return []
    }
}

// MARK: - Helper Methods
private extension TodoListViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }

    func setToast(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.toastMessage = "실행 취소"
        state.showToast = isPresented
    }
}
