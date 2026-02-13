//
//  HomeViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class HomeViewModel: Store {
    struct State {
        // UI
        var todoKindPreferences = TodoKind.allCases.map { TodoKindPreference(kind: $0, isVisible: true) }
        var pinnedTodos: [Todo] = []
        var showTodoKindPicker: Bool = false
        var showTodoEditor: Bool = false
        var showSearchView: Bool = false
        var selectedTodoKind: TodoKind?

        // User Input
        var searchText: String = ""
        var isSearching: Bool = false
        var reorderTodo: Bool = false

        // Side Effect UI
        var isLoading: Bool = false
        var toastMessage: String = ""
        var showToast: Bool = false
    }

    enum Action {
        // Life Cycle
        case onAppear

        // User
        case tapTodoKind(TodoKind)
        case upsertTodo(Todo)
        case orderTodoKindPreferences([TodoKindPreference])

        // Binding
        case updateSearching(Bool)
        case updateSearchText(String)
        case setReorderTodo(Bool)
        case setShowTodoEditor(Bool)
        case setShowTodoKindPicker(Bool)
        case setShowSearchView(Bool)
        case setShowToast(Bool)

        // Call from run
        case didFetchPinnedTodos([Todo])
    }

    enum SideEffect {
        case upsertTodo(Todo)
        case fetchPinnedTodos
    }

    private let upsertTodoUseCase: UpsertTodoUseCase
    private let fetchPinnedTodosUseCase: FetchPinnedTodosUseCase
    @Published private(set) var state = State()

    init(
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchPinnedTodosUseCase: FetchPinnedTodosUseCase
    ) {
        self.upsertTodoUseCase = upsertTodoUseCase
        self.fetchPinnedTodosUseCase = fetchPinnedTodosUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        switch action {
        case .onAppear:
            return [.fetchPinnedTodos]
        case .tapTodoKind(let kind):
            state.selectedTodoKind = kind
            state.showTodoKindPicker = false
            state.showTodoEditor = true
        case .updateSearching(let value):
            state.isSearching = value
        case .updateSearchText(let value):
            state.searchText = value
        case .setReorderTodo(let value):
            state.reorderTodo = value
        case .setShowTodoEditor(let value):
            state.showTodoEditor = value
            if !value {
                state.selectedTodoKind = nil
            }
        case .setShowTodoKindPicker(let value):
            state.showTodoKindPicker = value
        case .setShowSearchView(let value):
            state.showSearchView = value
        case .setShowToast(let value):
            state.showToast = value
        case .upsertTodo(let value):
            return [.upsertTodo(value)]
        case .orderTodoKindPreferences(let value):
            state.todoKindPreferences = value
        case .didFetchPinnedTodos(let todos):
            state.pinnedTodos = todos
        }

        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .upsertTodo(let todo):
            Task {
                try await upsertTodoUseCase.execute(todo)
            }
        case .fetchPinnedTodos:
            Task {
                let todos = try await fetchPinnedTodosUseCase.execute()
                send(.didFetchPinnedTodos(todos))
            }
        }
    }
}
