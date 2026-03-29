//
//  HomeViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation
import Combine

@Observable
final class HomeViewModel: Store {
    struct State: Equatable {
        var todoCategoryPreferences = TodoCategory.allCases.map {
            TodoCategoryPreference(category: $0, isVisible: true)
        }
        var recentTodos: [RecentTodoItem] = []
        var webPages: [WebPageItem] = []
        var isNetworkConnected: Bool = true
        var showContentPicker: Bool = false
        var showTodoEditor: Bool = false
        var showSearchView: Bool = false
        var webPageURLInput: String = "https://"
        var selectedTodoCategory: TodoCategory?
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
        case onAppear
        case networkStatusChanged(Bool)
        case setPresentation(Presentation, Bool)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case setLoading(LoadingTarget, Bool)
        case tapTodoCategory(TodoCategory)
        case orderTodoCategoryPreferences([TodoCategoryPreference])
        case addTodo(Todo)
        case updateRecentTodos([RecentTodoItem])
        case updateWebPageURLInput(String)
        case addWebPage
        case deleteWebPage(WebPageItem)
        case undoDeleteWebPage
        case updateWebPages([WebPageItem])
        case restoreWebPage(WebPageItem, Int)
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

    enum Presentation {
        case reorderTodo
        case todoEditor
        case contentPicker
        case searchView
    }

    enum LoadingTarget: Hashable {
        case recentTodos
        case webPage
        case overlay
    }

    private(set) var state = State()
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
        addWebPageUseCase: AddWebPageUseCase,
        deleteWebPageUseCase: DeleteWebPageUseCase,
        undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        fetchWebPagesUseCase: FetchWebPagesUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    ) {
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
        case .onAppear, .setPresentation, .setAlert, .setToast, .tapTodoCategory,
                .orderTodoCategoryPreferences, .addTodo, .updateWebPageURLInput,
                .addWebPage, .deleteWebPage, .undoDeleteWebPage:
            effects = reduceByView(action, state: &state)

        case .setLoading, .updateRecentTodos, .updateWebPages, .restoreWebPage:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
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
                        .map { RecentTodoItem(from: $0) }
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
                        .map { RecentTodoItem(from: $0) }
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
        case .deleteWebPage(let page, let index):
            beginLoading(for: .webPage, mode: .delayed)
            Task {
                do {
                    defer { endLoading(for: .webPage, mode: .delayed) }
                    try await deleteWebPageUseCase.execute(page.url.absoluteString)
                } catch {
                    send(.restoreWebPage(page, index))
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .undoDeleteWebPage(let urlString):
            beginLoading(for: .webPage, mode: .delayed)
            Task {
                defer { endLoading(for: .webPage, mode: .delayed) }

                var shouldPresentError = false

                do {
                    try await undoDeleteWebPageUseCase.execute(urlString)
                } catch {
                    shouldPresentError = true
                }

                do {
                    let pages = try await fetchWebPagesUseCase.execute("")
                    send(.updateWebPages(pages.map { WebPageItem(from: $0) }))
                } catch {
                    shouldPresentError = true
                }

                if shouldPresentError {
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
            return [.fetchRecentTodos, .fetchWebPages]
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
                deletedWebPageURLString = nil
            }
        case .tapTodoCategory(let category):
            state.selectedTodoCategory = category
            state.showContentPicker = false
            return [.showModalAfterDelay(.todoEditor)]
        case .orderTodoCategoryPreferences(let preferences):
            state.todoCategoryPreferences = preferences
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
                state.webPages.remove(at: index)
                setToast(&state, isPresented: true, for: .deleteWebPage)
                return [.deleteWebPage(page, index)]
            }
        case .undoDeleteWebPage:
            guard let deletedWebPageURLString else { return [] }
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
        case .updateRecentTodos(let todos):
            state.recentTodos = todos
        case .updateWebPages(let pages):
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

    func setLoading(
        _ state: inout State,
        loadingTarget: LoadingTarget,
        isLoading: Bool
    ) {
        switch loadingTarget {
        case .recentTodos:
            state.isRecentTodosLoading = isLoading
        case .webPage:
            state.isWebPageLoading = isLoading
        case .overlay:
            state.isAppending = isLoading
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
