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
        case tapEllipsisButton
        case tapPlusButton
        case tapSearchButton
        case tapTodoKind(TodoKind)
        case upsertTodo(Todo)
        case orderTodoKindPreferences([TodoKindPreference])

        // Binding
        case updateSearching(Bool)
        case updateSearchText(String)
        case setShowTodoEditor(Bool)
        case setShowSearchView(Bool)
        case closeOrderingSheet
        case closeTodoKindPicker
        case closeToast

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
        switch action {
        case .onAppear:
            return [.fetchPinnedTodos]
        case.tapEllipsisButton:
            state.reorderTodo = true
        case .tapPlusButton:
            state.showTodoKindPicker = true
        case .tapSearchButton:
            state.showSearchView = true
        case .tapTodoKind(let kind):
            state.selectedTodoKind = kind
            state.showTodoKindPicker = false
            state.showTodoEditor = true
        case .updateSearching(let isSearching):
            state.isSearching = isSearching
        case .updateSearchText(let text):
            state.searchText = text
        case .setShowTodoEditor(let isPresented):
            state.showTodoEditor = isPresented
            if !isPresented {
                state.selectedTodoKind = nil
            }
        case .setShowSearchView(let isPresented):
            state.showSearchView = isPresented
        case .upsertTodo(let todo):
            return [.upsertTodo(todo)]
        case .orderTodoKindPreferences(let preferences):
            state.todoKindPreferences = preferences

        case .closeOrderingSheet:
            state.reorderTodo = false
        case .closeTodoKindPicker:
            state.showTodoKindPicker = false
        case .closeToast:
            state.showToast = false

        case .didFetchPinnedTodos(let todos):
            state.pinnedTodos = todos
        }
        
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
