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
        var hasMore: Bool = false
        var nextCursor: TodoCursor?
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
        case tapToggleCompleted(TodoListItem)
        case tapTogglePinned(TodoListItem)
        case undoDelete

        // View
        case confirmDelete
        case onAppear
        case loadNextPage
        case setScope(TodoScope)
        case setSearchText(String)
        case setToast(isPresented: Bool)
        case upsertTodo(Todo)

        // Run
        case didToggleCompleted(TodoListItem)
        case didTogglePinned(TodoListItem)
        case setLoading(Bool)
        case appendTodos([TodoListItem], nextCursor: TodoCursor?)
        case resetPagination
        case setHasMore(Bool)
    }

    enum SideEffect {
        case fetch
        case loadNextPage
        case upsert(Todo)
        case delete(String)
        case toggleCompleted(TodoListItem)
        case togglePinned(TodoListItem)
    }

    @Published private(set) var state: State
    private let fetchTodosByKindUseCase: FetchTodosByKindUseCase
    private let fetchTodoByIDUseCase: FetchTodoByIDUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    private let pageSize = 20

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
        case .refresh, .setAlert, .setShowEditor, .swipeTodo, .tapFilterOption, .tapToggleCompleted, .tapTogglePinned, .undoDelete:
            effects = reduceByUser(action, state: &state)

        case .confirmDelete, .onAppear, .loadNextPage, .setScope, .setSearchText, .setToast, .upsertTodo:
            effects = reduceByView(action, state: &state)

        case .didToggleCompleted, .didTogglePinned, .setLoading, .appendTodos, .resetPagination, .setHasMore:
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
                    let page = try await fetchTodosByKindUseCase.execute(state.kind, cursor: nil)
                    send(.resetPagination)
                    send(.appendTodos(page.items.map { TodoListItem(from: $0) }, nextCursor: page.nextCursor))
                    let hasMore = page.items.count == pageSize && page.nextCursor != nil
                    send(.setHasMore(hasMore))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .loadNextPage:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let page = try await fetchTodosByKindUseCase.execute(state.kind, cursor: state.nextCursor)
                    send(.appendTodos(page.items.map { TodoListItem(from: $0) }, nextCursor: page.nextCursor))
                    let hasMore = page.items.count == pageSize && page.nextCursor != nil
                    send(.setHasMore(hasMore))
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
        case .toggleCompleted(let item):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    var todo = try await fetchTodoByIDUseCase.execute(item.id)
                    todo.isCompleted.toggle()
                    todo.completedAt = todo.isCompleted ? Date() : nil
                    try await upsertTodoUseCase.execute(todo)
                    send(.didToggleCompleted(TodoListItem(from: todo)))
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
            var effects: [SideEffect] = []
            if let (pendingItem, _) = state.pendingTask {
                effects = [.delete(pendingItem.id)]
            }

            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.pendingTask = (todo, index)
                state.todos.remove(at: index)
                setToast(&state, isPresented: true)
            }

            return effects
        case .tapFilterOption(let option):
            state.filterOption = option
        case .tapToggleCompleted(let todo):
            return [.toggleCompleted(todo)]
        case .tapTogglePinned(let todo):
            return [.togglePinned(todo)]
        case .undoDelete:
            guard let (todo, index) = state.pendingTask else { return [] }
            if index <= state.todos.count {
                state.todos.insert(todo, at: index)
            }
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
            state.pendingTask = nil
            return [.delete(item.id)]
        case .onAppear:
            return [.fetch]
        case .loadNextPage:
            guard state.hasMore, !state.isLoading, state.pendingTask == nil else { return [] }
            return [.loadNextPage]
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
        case .didToggleCompleted(let todo):
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.todos[index] = todo
            }
        case .didTogglePinned(let todo):
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.todos[index] = todo
            }
        case .setLoading(let value):
            state.isLoading = value
        case .appendTodos(let todos, let nextCursor):
            let filteredTodos: [TodoListItem]
            if let (pendingItem, _) = state.pendingTask {
                filteredTodos = todos.filter { $0.id != pendingItem.id }
            } else {
                filteredTodos = todos
            }
            state.todos.append(contentsOf: filteredTodos)
            state.nextCursor = nextCursor
        case .resetPagination:
            state.todos = []
            state.nextCursor = nil
            state.hasMore = false
        case .setHasMore(let value):
            state.hasMore = value
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
