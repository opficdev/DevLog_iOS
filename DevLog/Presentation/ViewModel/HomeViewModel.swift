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
        var webPages: [WebPageItem] = []
        var showTodoKindPicker: Bool = false
        var showTodoEditor: Bool = false
        var showSearchView: Bool = false
        var webPageURLInput: String = "https://"
        var selectedTodoKind: TodoKind?
        var searchText: String = ""
        var isSearching: Bool = false
        var reorderTodo: Bool = false
        var isPinnedLoading: Bool = false
        var isWebPageLoading: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
    }

    enum Action {
        case tapTodoKind(TodoKind)
        case orderTodoKindPreferences([TodoKindPreference])
        case setReorderTodo(Bool)
        case setShowTodoEditor(Bool)
        case setShowContentPicker(Bool)
        case setShowSearchView(Bool)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case onAppear
        case updateWebPageURLInput(String)
        case updateSearching(Bool)
        case updateSearchText(String)
        case upsertTodo(Todo)
        case addWebPage
        case fetchPinnedTodos([PinnedTodoItem])
        case fetchWebPages([WebPageItem])
        case setPinnedLoading(Bool)
        case setWebPageLoading(Bool)
    }

    enum SideEffect {
        case upsertTodo(Todo)
        case addWebPage(String)
        case fetchPinnedTodos
        case fetchWebPages
    }

    enum AlertType {
        case webPageInput
        case invalidURL
        case error
    }

    private let upsertTodoUseCase: UpsertTodoUseCase
    private let addWebPageUseCase: AddWebPageUseCase
    private let fetchPinnedTodosUseCase: FetchPinnedTodosUseCase
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    @Published private(set) var state = State()

    init(
        addWebPageUseCase: AddWebPageUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchPinnedTodosUseCase: FetchPinnedTodosUseCase,
        fetchWebPagesUseCase: FetchWebPagesUseCase
    ) {
        self.addWebPageUseCase = addWebPageUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.fetchPinnedTodosUseCase = fetchPinnedTodosUseCase
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .tapTodoKind, .orderTodoKindPreferences, .setReorderTodo,
                .setShowTodoEditor, .setShowContentPicker, .setShowSearchView,
                .updateWebPageURLInput, .setAlert:
            effects = reduceByUser(action, state: &state)

        case .onAppear, .updateSearching, .updateSearchText, .upsertTodo, .addWebPage:
            effects = reduceByView(action, state: &state)

        case .fetchPinnedTodos, .fetchWebPages, .setPinnedLoading, .setWebPageLoading:
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
                    try await upsertTodoUseCase.execute(todo)
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .addWebPage(let urlString):
            Task {
                do {
                    defer { send(.setWebPageLoading(false)) }
                    send(.setWebPageLoading(true))
                    _ = try await addWebPageUseCase.execute(urlString)
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.fetchWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .fetchPinnedTodos:
            Task {
                do {
                    defer { send(.setPinnedLoading(false)) }
                    send(.setPinnedLoading(true))
                    let todos = try await fetchPinnedTodosUseCase.execute()
                    send(.fetchPinnedTodos(todos.map { PinnedTodoItem(from: $0) }))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .fetchWebPages:
            Task {
                do {
                    defer { send(.setWebPageLoading(false)) }
                    send(.setWebPageLoading(true))
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.fetchWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
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
        case .updateWebPageURLInput(let text):
            state.webPageURLInput = text
        case .setAlert(let isPresented, let type):
            setAlert(&state, isPresented: isPresented, type: type)
        default:
            break
        }
        return []
    }

    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .onAppear:
            return [.fetchPinnedTodos, .fetchWebPages]
        case .updateSearching(let isSearching):
            state.isSearching = isSearching
        case .updateSearchText(let text):
            state.searchText = text
        case .upsertTodo(let todo):
            return [.upsertTodo(todo)]
        case .addWebPage:
            guard let normalizedURL = normalizedWebPageURL(state.webPageURLInput) else {
                setAlert(&state, isPresented: true, type: .invalidURL)
                return []
            }
            setAlert(&state, isPresented: false, type: nil)
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
        case .fetchWebPages(let pages):
            state.webPages = pages
        case .setPinnedLoading(let isLoading):
            state.isPinnedLoading = isLoading
        case .setWebPageLoading(let isLoading):
            state.isWebPageLoading = isLoading
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
        isPresented: Bool,
        type: AlertType?
    ) {
        switch type {
        case .webPageInput:
            state.alertTitle = "URL 추가"
            state.alertMessage = "웹페이지 URL을 입력해주세요."
            state.webPageURLInput = "https://"
        case .invalidURL:
            state.alertTitle = "URL 확인"
            state.alertMessage = "올바른 URL을 입력해주세요."
        case .error:
            state.alertTitle = "오류"
            state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }
        state.showAlert = isPresented
        state.alertType = type
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
