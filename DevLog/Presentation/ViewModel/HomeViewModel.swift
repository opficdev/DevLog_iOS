//
//  HomeViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

@Observable
final class HomeViewModel: Store {
    struct State: Equatable {
        var todoKindPreferences = TodoKind.allCases.map { TodoKindPreference(kind: $0, isVisible: true) }
        var recentTodos: [RecentTodoItem] = []
        var webPages: [WebPageItem] = []
        var showContentPicker: Bool = false
        var showTodoEditor: Bool = false
        var showSearchView: Bool = false
        var webPageURLInput: String = "https://"
        var selectedTodoKind: TodoKind?
        var searchText: String = ""
        var isSearching: Bool = false
        var reorderTodo: Bool = false
        var isRecentTodosLoading: Bool = false
        var isWebPageLoading: Bool = false
        var isAppending: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
        var showToast: Bool = false
        var toastType: ToastType?
        var toastMessage: String = ""
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
        case addTodo(Todo)
        case addWebPage
        case deleteWebPage(WebPageItem)
        case undoDeleteWebPage
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case fetchRecentTodos([RecentTodoItem])
        case fetchWebPages([WebPageItem])
        case restoreWebPage(WebPageItem, Int)
        case setRecentTodosLoading(Bool)
        case setWebPageLoading(Bool)
        case setAppending(Bool)
    }

    enum SideEffect {
        case addTodo(Todo)
        case addWebPage(String)
        case deleteWebPage(WebPageItem, Int)
        case undoDeleteWebPage(String)
        case fetchRecentTodos
        case fetchWebPages
        case showModalAfterDelay(ModalType)
    }

    enum AlertType {
        case webPageInput
        case invalidURL
        case error
    }

    enum ToastType {
        case deleteWebPage
    }

    enum ModalType {
        case todoEditor
        case urlInputAlert
    }

    private(set) var state = State()
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let addWebPageUseCase: AddWebPageUseCase
    private let deleteWebPageUseCase: DeleteWebPageUseCase
    private let undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase
    private let fetchTodosUseCase: FetchTodosUseCase
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    private var deletedWebPageURLString: String?

    init(
        addWebPageUseCase: AddWebPageUseCase,
        deleteWebPageUseCase: DeleteWebPageUseCase,
        undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        fetchWebPagesUseCase: FetchWebPagesUseCase
    ) {
        self.addWebPageUseCase = addWebPageUseCase
        self.deleteWebPageUseCase = deleteWebPageUseCase
        self.undoDeleteWebPageUseCase = undoDeleteWebPageUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .tapTodoKind, .orderTodoKindPreferences, .setReorderTodo,
                .setShowTodoEditor, .setShowContentPicker, .setShowSearchView,
                .updateWebPageURLInput, .setAlert, .deleteWebPage,
                .undoDeleteWebPage, .setToast:
            effects = reduceByUser(action, state: &state)

        case .onAppear, .updateSearching, .updateSearchText, .addTodo, .addWebPage:
            effects = reduceByView(action, state: &state)

        case .fetchRecentTodos, .fetchWebPages, .restoreWebPage, .setRecentTodosLoading,
                .setWebPageLoading, .setAppending:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .addTodo(let todo):
            Task {
                do {
                    send(.setAppending(true))
                    try await upsertTodoUseCase.execute(todo)
                    let page = try await fetchRecentTodos()
                    let items = page.items
                        .filter { $0.createdAt != $0.updatedAt }
                        .prefix(5)
                        .map { RecentTodoItem(from: $0) }
                    send(.fetchRecentTodos(items))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .fetchRecentTodos:
            Task {
                do {
                    defer { send(.setRecentTodosLoading(false)) }
                    send(.setRecentTodosLoading(true))
                    let page = try await fetchRecentTodos()
                    let items = page.items
                        .filter { $0.createdAt != $0.updatedAt }
                        .prefix(5)
                        .map { RecentTodoItem(from: $0) }
                    send(.fetchRecentTodos(items))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .addWebPage(let urlString):
            Task {
                do {
                    defer { send(.setAppending(false)) }
                    send(.setAppending(true))
                    try await addWebPageUseCase.execute(urlString)
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.fetchWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .deleteWebPage(let page, let index):
            Task {
                do {
                    defer { send(.setWebPageLoading(false)) }
                    send(.setWebPageLoading(true))
                    try await deleteWebPageUseCase.execute(page.url.absoluteString)
                } catch {
                    send(.restoreWebPage(page, index))
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .undoDeleteWebPage(let urlString):
            Task {
                defer { send(.setWebPageLoading(false)) }
                send(.setWebPageLoading(true))

                var shouldPresentError = false

                do {
                    try await undoDeleteWebPageUseCase.execute(urlString)
                } catch {
                    shouldPresentError = true
                }

                do {
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.fetchWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    shouldPresentError = true
                }

                if shouldPresentError {
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
        case .showModalAfterDelay(let type):
            Task {
                try await Task.sleep(for: .seconds(0.1))
                switch type {
                case .todoEditor:
                    send(.setShowTodoEditor(true))
                case .urlInputAlert:
                    send(.setAlert(isPresented: true, type: .webPageInput))
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
            state.showContentPicker = false
            return [.showModalAfterDelay(.todoEditor)]
        case .orderTodoKindPreferences(let preferences):
            state.todoKindPreferences = preferences
        case .setReorderTodo(let presented):
            state.reorderTodo = presented
        case .setShowTodoEditor(let presented):
            state.showTodoEditor = presented
            if !presented { state.selectedTodoKind = nil }
        case .setShowContentPicker(let presented):
            state.showContentPicker = presented
        case .setShowSearchView(let presented):
            state.showSearchView = presented
        case .updateWebPageURLInput(let text):
            state.webPageURLInput = text
        case .setAlert(let presented, let type):
            if presented && type == .webPageInput && state.showContentPicker {
                state.showContentPicker = false
                return [.showModalAfterDelay(.urlInputAlert)]
            }
            setAlert(&state, isPresented: presented, type: type)
        case .deleteWebPage(let page):
            if let index = state.webPages.firstIndex(where: { $0.id == page.id }) {
                deletedWebPageURLString = page.url.absoluteString
                state.webPages.remove(at: index)
                setToast(&state, isPresented: true, for: .deleteWebPage)
                return [.deleteWebPage(page, index)]
            }
        case .undoDeleteWebPage:
            guard let deletedWebPageURLString else { return [] }
            self.deletedWebPageURLString = nil
            return [.undoDeleteWebPage(deletedWebPageURLString)]
        case .setToast(let isPresented, let type):
            setToast(&state, isPresented: isPresented, for: type)
            if !isPresented {
                deletedWebPageURLString = nil
            }
        default:
            break
        }
        return []
    }

    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .onAppear:
            return [.fetchRecentTodos, .fetchWebPages]
        case .updateSearching(let isSearching):
            state.isSearching = isSearching
        case .updateSearchText(let text):
            state.searchText = text
        case .addTodo(let todo):
            return [.addTodo(todo)]
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
        case .fetchRecentTodos(let todos):
            state.recentTodos = todos
        case .fetchWebPages(let pages):
            state.webPages = pages
        case .restoreWebPage(let page, let index):
            if state.webPages.contains(where: { $0.id == page.id }) { break }
            if index <= state.webPages.count {
                state.webPages.insert(page, at: index)
            } else {
                state.webPages.append(page)
            }
            if deletedWebPageURLString == page.url.absoluteString {
                deletedWebPageURLString = nil
            }
        case .setRecentTodosLoading(let isLoading):
            state.isRecentTodosLoading = isLoading
        case .setWebPageLoading(let isLoading):
            state.isWebPageLoading = isLoading
        case .setAppending(let isLoading):
            state.isAppending = isLoading
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

    func setToast(
        _ state: inout State,
        isPresented: Bool,
        for type: ToastType?
    ) {
        switch type {
        case .deleteWebPage:
            state.toastMessage = "실행 취소"
        case .none:
            state.toastMessage = ""
        }
        state.showToast = isPresented
        state.toastType = type
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

    func fetchRecentTodos() async throws -> TodoPage {
        try await fetchTodosUseCase.execute(
            TodoQuery(
                sortTarget: .updatedAt,
                sortOrder: .latest,
                pageSize: 100
            ),
            cursor: nil
        )
    }
}
