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
        var showToast: Bool = false
        var toastMessage: String = ""
        var pendingTask: (Todo, Int)?
    }

    enum FilterOption {
        case create, update, day, week, month, year
    }

    enum Action {
        // User
        case tapTogglePinned(Todo)
        case swipeTodo(Todo)
        case tapFilterOption(FilterOption)
        case upsertTodo(Todo)
        case undoDelete
        case confirmDelete

        // View
        case onAppear, refresh
        case openEditor
        case closeEditor
        case closeAlert
        case setScope(TodoScope)
        case setSearchText(String)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case setLoading(Bool)
        case setTodos([Todo])

        // Run
        case didShowAlert(String)
        case didTogglePinned(Todo)
    }
    
    enum ToastType {
        case delete
    }

    enum SideEffect {
        case fetch
        case upsert(Todo)
        case delete(Todo)
        case togglePinned(Todo)
    }

    private let fetchTodosByKindUseCase: FetchTodosByKindUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    @Published private(set) var state: State

    init(
        fetchTodosByKindUseCase: FetchTodosByKindUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        deleteTodoUseCase: DeleteTodoUseCase,
        kind: TodoKind
    ) {
        self.fetchTodosByKindUseCase = fetchTodosByKindUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.state = State(kind: kind)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        
        switch action {
        case .onAppear, .refresh:
            return [.fetch]
        case .tapTogglePinned(let todo):
            return [.togglePinned(todo)]
        case .swipeTodo(let todo):
            guard let index = state.todos.firstIndex(where: { $0.id == todo.id }) else {
                return []
            }
            state.pendingTask = (todo, index)
            state.todos.remove(at: index)
            setToast(&state, isPresented: true, for: .delete)
        case .tapFilterOption(let option):
            state.filterOption = option
        case .upsertTodo(let todo):
            return [.upsert(todo)]
        case .undoDelete:
            guard let (todo, index) = state.pendingTask else { return [] }
            state.todos.insert(todo, at: index)
            state.pendingTask = nil
        case .confirmDelete:
            guard let (item, _) = state.pendingTask else {
                return []
            }
            return [.delete(item)]
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
        case .setToast(let isPresented, let type):
            setToast(&state, isPresented: isPresented, for: type)
        case .setLoading(let value):
            state.isLoading = value
        case .setTodos(let todos):
            state.todos = todos
        case .didShowAlert(let message):
            state.alertMessage = message
            state.showAlert = true
        case .didTogglePinned(let todo):
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.todos[index] = todo
            }
        }
        
        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetch:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let todos = try await fetchTodosByKindUseCase.execute(state.kind)
                    send(.setTodos(todos))
                } catch {
                    send(.didShowAlert(error.localizedDescription))
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
                    send(.didShowAlert(error.localizedDescription))
                }
            }
        case .togglePinned(let item):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    var todo = item
                    todo.isPinned.toggle()
                    try await upsertTodoUseCase.execute(todo)
                    send(.didTogglePinned(todo))
                } catch {
                    send(.didShowAlert(error.localizedDescription))
                }
            }
        case .delete(let item):
            Task {
                do {
                    try await deleteTodoUseCase.execute(item.id)
                } catch {
                    send(.didShowAlert(error.localizedDescription))
                }
            }
        }
    }
}
private extension TodoViewModel {
    func setToast(
        _ state: inout State,
        isPresented: Bool,
        for type: ToastType?
    ) {
        switch type {
        case .delete:
            state.toastMessage = "실행 취소"
        case .none:
            state.toastMessage = ""
        }
        state.showToast = isPresented
    }
}
