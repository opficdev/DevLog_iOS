//
//  HomeViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class HomeViewModel: Store {
    struct State: Equatable {
        var todoKindPreferences = TodoKind.allCases.map { TodoKindPreference(kind: $0, isVisible: true) }
        var pinnedTodos: [PinnedTodoItem] = []
        var webPages: [WebPageItem] = []
        var showContentPicker: Bool = false
        var showTodoEditor: Bool = false
        var showSearchView: Bool = false
        var webPageURLInput: String = "https://"
        var selectedTodoKind: TodoKind?
        var searchText: String = ""
        var isSearching: Bool = false
        var reorderTodo: Bool = false
        var isPinnedLoading: Bool = false
        var isWebPageLoading: Bool = false
        var isWebPageInputLoading: Bool = false
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
        case upsertTodo(Todo)
        case addWebPage
        case deleteWebPage(WebPageItem)
        case undoDeleteWebPage
        case confirmDeleteWebPage
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case fetchPinnedTodos([PinnedTodoItem])
        case fetchWebPages([WebPageItem])
        case setPinnedLoading(Bool)
        case setWebPageLoading(Bool)
        case setWebPageInputLoading(Bool)
    }

    enum SideEffect {
        case upsertTodo(Todo)
        case addWebPage(String)
        case deleteWebPage(String)
        case fetchPinnedTodos
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

    @Published private(set) var state = State()
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let addWebPageUseCase: AddWebPageUseCase
    private let deleteWebPageUseCase: DeleteWebPageUseCase
    private let fetchPinnedTodosUseCase: FetchPinnedTodosUseCase
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    private var pendingTask: (WebPageItem, Int)?

    init(
        addWebPageUseCase: AddWebPageUseCase,
        deleteWebPageUseCase: DeleteWebPageUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchPinnedTodosUseCase: FetchPinnedTodosUseCase,
        fetchWebPagesUseCase: FetchWebPagesUseCase
    ) {
        self.addWebPageUseCase = addWebPageUseCase
        self.deleteWebPageUseCase = deleteWebPageUseCase
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
                .updateWebPageURLInput, .setAlert, .deleteWebPage,
                .undoDeleteWebPage, .setToast:
            effects = reduceByUser(action, state: &state)

        case .onAppear, .updateSearching, .updateSearchText, .upsertTodo,
                .addWebPage, .confirmDeleteWebPage:
            effects = reduceByView(action, state: &state)

        case .fetchPinnedTodos, .fetchWebPages, .setPinnedLoading,
                .setWebPageLoading, .setWebPageInputLoading:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
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
                    defer { send(.setWebPageInputLoading(false)) }
                    send(.setWebPageInputLoading(true))
                    try await addWebPageUseCase.execute(urlString)
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.fetchWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    send(.setWebPageInputLoading(false))
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .deleteWebPage(let urlString):
            Task {
                do {
                    defer { send(.setWebPageLoading(false)) }
                    send(.setWebPageLoading(true))
                    try await deleteWebPageUseCase.execute(urlString)
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.fetchWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    send(.setWebPageLoading(false))
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
                pendingTask = (page, index)
                state.webPages.remove(at: index)
                setToast(&state, isPresented: true, for: .deleteWebPage)
            }
        case .undoDeleteWebPage:
            guard let (page, index) = pendingTask else { return [] }
            state.webPages.insert(page, at: index)
            pendingTask = nil
        case .setToast(let isPresented, let type):
            setToast(&state, isPresented: isPresented, for: type)
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
        case .confirmDeleteWebPage:
            guard let (page, _) = pendingTask else { return [] }
            pendingTask = nil
            return [.deleteWebPage(page.url.absoluteString)]
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
            let filteredPages: [WebPageItem]
            if let (pendingPage, _) = pendingTask {
                filteredPages = pages.filter { $0.id != pendingPage.id }
            } else {
                filteredPages = pages
            }
            state.webPages = filteredPages
        case .setPinnedLoading(let isLoading):
            state.isPinnedLoading = isLoading
        case .setWebPageLoading(let isLoading):
            state.isWebPageLoading = isLoading
        case .setWebPageInputLoading(let isLoading):
            state.isWebPageInputLoading = isLoading
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
}
