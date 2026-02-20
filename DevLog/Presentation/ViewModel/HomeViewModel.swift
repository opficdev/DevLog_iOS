//
//  HomeViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class HomeViewModel: Store {
    struct State {
        var todoKindPreferences = TodoKind.allCases.map { TodoKindPreference(kind: $0, isVisible: true) }
        var pinnedTodos: [PinnedTodoItem] = []
        var showTodoKindPicker: Bool = false
        var showTodoEditor: Bool = false
        var showSearchView: Bool = false
        var showWebPageAlert: Bool = false
        var webPageURLInput: String = "https://"
        var selectedTodoKind: TodoKind?
        var searchText: String = ""
        var isSearching: Bool = false
        var reorderTodo: Bool = false
        var isLoading: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }

    enum Action {
        case tapTodoKind(TodoKind)
        case orderTodoKindPreferences([TodoKindPreference])
        case setReorderTodo(Bool)
        case setShowTodoEditor(Bool)
        case setShowContentPicker(Bool)
        case setShowSearchView(Bool)
        case setShowWebPageAlert(Bool)
        case updateWebPageURLInput(String)
        case setAlert(Bool)
        case onAppear
        case updateSearching(Bool)
        case updateSearchText(String)
        case upsertTodo(Todo)
        case addWebPage
        case fetchPinnedTodos([PinnedTodoItem])
        case setLoading(Bool)
    }

    enum SideEffect {
        case upsertTodo(Todo)
        case addWebPage(String)
        case fetchPinnedTodos
    }

    private let upsertTodoUseCase: UpsertTodoUseCase
    private let addWebPageUseCase: AddWebPageUseCase
    private let fetchPinnedTodosUseCase: FetchPinnedTodosUseCase
    @Published private(set) var state = State()

    init(
        addWebPageUseCase: AddWebPageUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchPinnedTodosUseCase: FetchPinnedTodosUseCase
    ) {
        self.addWebPageUseCase = addWebPageUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.fetchPinnedTodosUseCase = fetchPinnedTodosUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .tapTodoKind, .orderTodoKindPreferences, .setReorderTodo,
                .setShowTodoEditor, .setShowContentPicker, .setShowSearchView,
                .setShowWebPageAlert, .updateWebPageURLInput, .setAlert:
            effects = reduceByUser(action, state: &state)

        case .onAppear, .updateSearching, .updateSearchText, .upsertTodo, .addWebPage:
            effects = reduceByView(action, state: &state)

        case .fetchPinnedTodos, .setLoading:
            effects = reduceByRun(action, state: &state)
        }

        self.state = state
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .upsertTodo(let todo):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    try await upsertTodoUseCase.execute(todo)
                } catch {
                    send(.setAlert(true))
                }
            }
        case .addWebPage(let urlString):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    _ = try await addWebPageUseCase.execute(urlString)
                } catch {
                    send(.setAlert(true))
                }
            }
        case .fetchPinnedTodos:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let todos = try await fetchPinnedTodosUseCase.execute()
                    send(.fetchPinnedTodos(todos.map { PinnedTodoItem(from: $0) }))
                } catch {
                    send(.setAlert(true))
                }
            }
        }
    }
}

// MARK: - Reduce Methods
private extension HomeViewModel {
    func reduceByUser(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .tapTodoKind(let kind):
            state.selectedTodoKind = kind
            state.showTodoKindPicker = false
            state.showTodoEditor = true
        case .orderTodoKindPreferences(let preferences):
            state.todoKindPreferences = preferences
        case .setReorderTodo(let isPresented):
            state.reorderTodo = isPresented
        case .setShowTodoEditor(let isPresented):
            state.showTodoEditor = isPresented
            if !isPresented { state.selectedTodoKind = nil }
        case .setShowContentPicker(let isPresented):
            state.showTodoKindPicker = isPresented
        case .setShowSearchView(let isPresented):
            state.showSearchView = isPresented
        case .setShowWebPageAlert(let isPresented):
            state.showWebPageAlert = isPresented
            if isPresented {
                state.webPageURLInput = "https://"
            }
        case .updateWebPageURLInput(let text):
            state.webPageURLInput = text
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        default:
            break
        }
        return []
    }

    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .onAppear:
            return [.fetchPinnedTodos]
        case .updateSearching(let isSearching):
            state.isSearching = isSearching
        case .updateSearchText(let text):
            state.searchText = text
        case .upsertTodo(let todo):
            return [.upsertTodo(todo)]
        case .addWebPage:
            guard let normalizedURL = normalizedWebPageURL(state.webPageURLInput) else {
                return []
            }
            state.showWebPageAlert = false
            return [.addWebPage(normalizedURL)]
        default:
            break
        }
        return []
    }

    func reduceByRun(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .fetchPinnedTodos(let todos):
            state.pinnedTodos = todos
        case .setLoading(let isLoading):
            state.isLoading = isLoading
        default:
            break
        }
        return []
    }
}

// MARK: - Helper Methods
private extension HomeViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }

    func normalizedWebPageURL(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed == "https://" || trimmed == "http://" {
            return nil
        }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }
}
