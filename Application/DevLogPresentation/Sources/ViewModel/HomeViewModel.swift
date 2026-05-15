//
//  HomeViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation
import Combine
import DevLogDomain
import DevLogData

@Observable
final class HomeViewModel: Store {
    struct State: Equatable {
        var preferences: [TodoCategoryItem] = []
        var recentTodos: [RecentTodoItem] = []
        var webPages: [WebPageItem] = []
        var needsWebPageRefresh = false
        var isNetworkConnected: Bool = true
        var showContentPicker: Bool = false
        var showTodoEditor: Bool = false
        var showSearchView: Bool = false
        var webPageURLInput: String = "https://"
        var selectedTodoCategory: TodoCategory?
        var reorderTodo: Bool = false
        var isPreferencesLoading: Bool = false
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
        case onAppear
        case networkStatusChanged(Bool)
        case setPresentation(Presentation, Bool)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case refreshWebPages
        case setLoading(LoadingTarget, Bool)
        case setWebPageHidden(URL, Bool)
        case handleWebPageDeleteFailure(URL)
        case tapTodoCategory(TodoCategory)
        case orderTodoCategory([TodoCategoryItem])
        case setTodoCategory([TodoCategoryItem])
        case addTodo(Todo)
        case updateRecentTodos([RecentTodoItem])
        case updateWebPageURLInput(String)
        case addWebPage
        case deleteWebPage(WebPageItem)
        case undoDeleteWebPage
        case updateWebPages([WebPageItem])
    }

    enum SideEffect {
        case addTodo(Todo)
        case addWebPage(String)
        case deleteWebPage(WebPageItem)
        case undoDeleteWebPage(String)
        case fetchTodoCategoryPreferences
        case updateTodoCategoryPreferences([TodoCategoryItem])
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

    enum Presentation {
        case reorderTodo
        case todoEditor
        case contentPicker
        case searchView
    }

    enum LoadingTarget: Hashable {
        case preferences
        case recentTodos
        case webPage
        case overlay
    }

    private(set) var state = State()
    private let fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase
    private let updatePreferencesUseCase: UpdateTodoCategoryPreferencesUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let addWebPageUseCase: AddWebPageUseCase
    private let deleteWebPageUseCase: DeleteWebPageUseCase
    private let undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase
    private let fetchTodosUseCase: FetchTodosUseCase
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    private let networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    private let loadingState = LoadingState()
    private var deletedWebPageURLString: String?
    private var cancellables = Set<AnyCancellable>()

    init(
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase,
        updatePreferencesUseCase: UpdateTodoCategoryPreferencesUseCase,
        addWebPageUseCase: AddWebPageUseCase,
        deleteWebPageUseCase: DeleteWebPageUseCase,
        undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        fetchWebPagesUseCase: FetchWebPagesUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    ) {
        self.fetchPreferencesUseCase = fetchPreferencesUseCase
        self.updatePreferencesUseCase = updatePreferencesUseCase
        self.addWebPageUseCase = addWebPageUseCase
        self.deleteWebPageUseCase = deleteWebPageUseCase
        self.undoDeleteWebPageUseCase = undoDeleteWebPageUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
        self.networkConnectivityUseCase = networkConnectivityUseCase

        setupNetworkObserving()
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .networkStatusChanged(let isConnected):
            state.isNetworkConnected = isConnected
        case .onAppear, .setPresentation, .setAlert, .setToast, .refreshWebPages,
                .tapTodoCategory, .orderTodoCategory, .addTodo, .updateWebPageURLInput,
                .addWebPage, .deleteWebPage, .undoDeleteWebPage:
            effects = reduceByView(action, state: &state)

        case .setLoading, .setWebPageHidden, .handleWebPageDeleteFailure, .setTodoCategory,
                .updateRecentTodos, .updateWebPages:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchTodoCategoryPreferences:
            beginLoading(for: .preferences, mode: .immediate)
            Task {
                do {
                    defer { endLoading(for: .preferences, mode: .immediate) }
                    let preferences = try await fetchPreferencesUseCase.execute()
                    send(.setTodoCategory(preferences.map(TodoCategoryItem.init(from:))))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .updateTodoCategoryPreferences(let items):
            Task {
                do {
                    try await updatePreferencesUseCase.execute(items.map(\.preference))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .addTodo(let todo):
            beginLoading(for: .overlay, mode: .delayed)
            Task {
                do {
                    defer { endLoading(for: .overlay, mode: .delayed) }
                    try await upsertTodoUseCase.execute(todo)
                    let page = try await fetchRecentTodos()
                    let items = page.items
                        .filter { $0.createdAt != $0.updatedAt }
                        .prefix(5)
                        .compactMap { RecentTodoItem(from: $0) }
                    send(.updateRecentTodos(items))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .fetchRecentTodos:
            beginLoading(for: .recentTodos, mode: .immediate)
            Task {
                do {
                    defer { endLoading(for: .recentTodos, mode: .immediate) }
                    let page = try await fetchRecentTodos()
                    let items = page.items
                        .filter { $0.createdAt != $0.updatedAt }
                        .prefix(5)
                        .compactMap { RecentTodoItem(from: $0) }
                    send(.updateRecentTodos(items))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .addWebPage(let urlString):
            beginLoading(for: .overlay, mode: .delayed)
            Task {
                do {
                    defer { endLoading(for: .overlay, mode: .delayed) }
                    try await addWebPageUseCase.execute(urlString)
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.updateWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .deleteWebPage(let page):
            Task {
                do {
                    try await deleteWebPageUseCase.execute(page.url.absoluteString)
                } catch {
                    send(.handleWebPageDeleteFailure(page.id))
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .undoDeleteWebPage(let urlString):
            Task {
                do {
                    try await undoDeleteWebPageUseCase.execute(urlString)
                    try await addWebPageUseCase.execute(urlString)
                } catch {
                    if let webPageURL = URL(string: urlString) {
                        send(.setWebPageHidden(webPageURL, true))
                    }
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .fetchWebPages:
            beginLoading(for: .webPage, mode: .immediate)
            Task {
                do {
                    defer { endLoading(for: .webPage, mode: .immediate) }
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.updateWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .showModalAfterDelay(let type):
            Task {
                try await Task.sleep(for: .seconds(0.1))
                switch type {
                case .todoEditor:
                    send(.setPresentation(.todoEditor, true))
                case .urlInputAlert:
                    send(.setAlert(isPresented: true, type: .webPageInput))
                }
            }
        }
    }
}

// MARK: - Reduce Methods
private extension HomeViewModel {
    // swiftlint:disable cyclomatic_complexity
    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .onAppear:
            return [.fetchTodoCategoryPreferences, .fetchRecentTodos, .fetchWebPages]
        case .refreshWebPages:
            return [.fetchWebPages]
        case .setPresentation(let presentation, let isPresented):
            setPresentation(&state, presentation: presentation, isPresented: isPresented)
        case .setAlert(let presented, let type):
            if presented && type == .webPageInput && state.showContentPicker {
                state.showContentPicker = false
                return [.showModalAfterDelay(.urlInputAlert)]
            }
            setAlert(&state, isPresented: presented, type: type)
        case .setToast(let isPresented, let type):
            setToast(&state, isPresented: isPresented, for: type)
            if !isPresented {
                state.webPages.removeAll { $0.isHidden }
                deletedWebPageURLString = nil
            }
        case .tapTodoCategory(let category):
            state.selectedTodoCategory = category
            state.showContentPicker = false
            return [.showModalAfterDelay(.todoEditor)]
        case .orderTodoCategory(let preferences):
            state.preferences = preferences
            state.recentTodos = syncRecentTodos(state.recentTodos, preferences: preferences)
            return [.updateTodoCategoryPreferences(preferences)]
        case .addTodo(let todo):
            return [.addTodo(todo)]
        case .updateWebPageURLInput(let text):
            state.webPageURLInput = text
        case .addWebPage:
            guard let normalizedURL = normalizedWebPageURL(state.webPageURLInput) else {
                setAlert(&state, isPresented: true, type: .invalidURL)
                return []
            }
            setAlert(&state, isPresented: false, type: nil)
            return [.addWebPage(normalizedURL)]
        case .deleteWebPage(let page):
            if let index = state.webPages.firstIndex(where: { $0.id == page.id }) {
                deletedWebPageURLString = page.url.absoluteString
                state.webPages[index].isHidden = true
                setToast(&state, isPresented: true, for: .deleteWebPage)
                return [.deleteWebPage(page)]
            }
        case .undoDeleteWebPage:
            guard let deletedWebPageURLString else { return [] }
            if let index = state.webPages.firstIndex(where: {
                $0.url.absoluteString == deletedWebPageURLString
            }) {
                state.webPages[index].isHidden = false
            }
            self.deletedWebPageURLString = nil
            return [.undoDeleteWebPage(deletedWebPageURLString)]
        default:
            break
        }
        return []
    }
    // swiftlint:enable cyclomatic_complexity

    func reduceByRun(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .setLoading(let loadingTarget, let isLoading):
            setLoading(&state, loadingTarget: loadingTarget, isLoading: isLoading)
        case .setWebPageHidden(let webPageURL, let isHidden):
            if let index = state.webPages.firstIndex(where: { $0.id == webPageURL }) {
                state.webPages[index].isHidden = isHidden
            }
        case .handleWebPageDeleteFailure(let webPageURL):
            if let index = state.webPages.firstIndex(where: { $0.id == webPageURL }) {
                state.webPages[index].isHidden = false
            } else {
                state.needsWebPageRefresh = true
            }
        case .setTodoCategory(let preferences):
            state.preferences = preferences
            state.recentTodos = syncRecentTodos(state.recentTodos, preferences: preferences)
        case .updateRecentTodos(let todos):
            state.recentTodos = todos
        case .updateWebPages(let pages):
            state.webPages = pages
            state.needsWebPageRefresh = false
        default:
            break
        }
        return []
    }
}

// MARK: - Helper Methods
private extension HomeViewModel {
    func setPresentation(
        _ state: inout State,
        presentation: Presentation,
        isPresented: Bool
    ) {
        switch presentation {
        case .reorderTodo:
            state.reorderTodo = isPresented
        case .todoEditor:
            state.showTodoEditor = isPresented
            if !isPresented { state.selectedTodoCategory = nil }
        case .contentPicker:
            state.showContentPicker = isPresented
        case .searchView:
            state.showSearchView = isPresented
        }
    }

    func setAlert(
        _ state: inout State,
        isPresented: Bool,
        type: AlertType?
    ) {
        switch type {
        case .webPageInput:
            state.alertTitle = String(localized: "home_webpage_input_title")
            state.alertMessage = String(localized: "home_webpage_input_message")
            state.webPageURLInput = "https://"
        case .invalidURL:
            state.alertTitle = String(localized: "home_invalid_url_title")
            state.alertMessage = String(localized: "home_invalid_url_message")
        case .error:
            state.alertTitle = String(localized: "common_error_title")
            state.alertMessage = String(localized: "common_error_message")
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
            state.toastMessage = String(localized: "common_undo")
        case .none:
            state.toastMessage = ""
        }
        state.showToast = isPresented
        state.toastType = type
    }

    func setLoading(
        _ state: inout State,
        loadingTarget: LoadingTarget,
        isLoading: Bool
    ) {
        switch loadingTarget {
        case .preferences:
            state.isPreferencesLoading = isLoading
        case .recentTodos:
            state.isRecentTodosLoading = isLoading
        case .webPage:
            state.isWebPageLoading = isLoading
        case .overlay:
            state.isAppending = isLoading
        }
    }

    func syncRecentTodos(
        _ recentTodos: [RecentTodoItem],
        preferences: [TodoCategoryItem]
    ) -> [RecentTodoItem] {
        recentTodos.map { recentTodo in
            guard let item = preferences.first(where: {
                $0.category.storageValue == recentTodo.category.storageValue
            }) else {
                return recentTodo
            }

            var recentTodo = recentTodo
            recentTodo.category = item.category
            return recentTodo
        }
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

    private func beginLoading(
        for target: LoadingTarget,
        mode: LoadingState.Mode
    ) {
        loadingState.begin(target: target, mode: mode) { [weak self] target, isLoading in
            self?.send(.setLoading(target, isLoading))
        }
    }

    private func endLoading(
        for target: LoadingTarget,
        mode: LoadingState.Mode
    ) {
        loadingState.end(target: target, mode: mode) { [weak self] target, isLoading in
            self?.send(.setLoading(target, isLoading))
        }
    }

    func setupNetworkObserving() {
        networkConnectivityUseCase.observe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.send(.networkStatusChanged(isConnected))
            }
            .store(in: &cancellables)
    }
}
