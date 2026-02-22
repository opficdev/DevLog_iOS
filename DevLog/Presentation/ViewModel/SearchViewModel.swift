//
//  SearchViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 2/8/26.
//

import Foundation
import OrderedCollections

final class SearchViewModel: Store {
    struct State {
        var isLoading: Bool = false
        var isSearching: Bool = false
        var searchQuery: String = ""
        var selectedWebPage: WebPageItem?
        var webPages: [WebPageItem] = []
        var todos: [TodoListItem] = []
        var recentQueries: OrderedSet<String> = []
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var showAllTodos: Bool = false
        var showAllWebPages: Bool = false
    }

    enum Action {
        case fetchWebPage([WebPageItem])
        case fetchTodos([TodoListItem])
        case selectWebPage(WebPageItem)
        case addRecentQuery(String)
        case removeRecentQuery(String)
        case clearRecentQueries
        case applySearchQuery(String)   // 뷰모델에서 쿼리에 대해 디바운스 적용
        case setAlert(Bool)
        case setLoading(Bool)
        case setSearching(Bool)
        case setSearchQuery(String) // 뷰에서 쿼리 입력을 적용
        case setShowAllTodos(Bool)
        case setShowAllWebPages(Bool)
    }

    enum SideEffect {
        case fetch(String)
    }

    @Published private(set) var state: State = .init()
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    private let fetchTodosByKeywordUseCase: FetchTodosByKeywordUseCase
    private let userDefaults: UserDefaults
    let contentsLimit: Int = 5

    private enum DefaultsKey {
        static let recentQueries = "Search.recentQueries"
    }

    private let maxRecentQueries = 20
    private let searchDebounceDelay: Double = 0.4
    private var searchDebounceTask: Task<Void, Never>?

    init(
        fetchWebPagesUseCase: FetchWebPagesUseCase,
        fetchTodosByKeywordUseCase: FetchTodosByKeywordUseCase,
        userDefaults: UserDefaults = .standard
    ) {
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
        self.fetchTodosByKeywordUseCase = fetchTodosByKeywordUseCase
        self.userDefaults = userDefaults
        self.state.recentQueries = Self.loadRecentQueries(userDefaults: userDefaults)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .fetchWebPage(let items):
            state.webPages = items
        case .fetchTodos(let items):
            state.todos = items
        case .selectWebPage(let item):
            state.selectedWebPage = item
        case .addRecentQuery(let query):
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { break }
            state.recentQueries.remove(trimmed)
            state.recentQueries.insert(trimmed, at: 0)
            if maxRecentQueries < state.recentQueries.count {
                state.recentQueries = OrderedSet(state.recentQueries.prefix(maxRecentQueries))
            }
            saveRecentQueries(state.recentQueries)
        case .removeRecentQuery(let query):
            state.recentQueries.remove(query)
            saveRecentQueries(state.recentQueries)
        case .clearRecentQueries:
            state.recentQueries = []
            saveRecentQueries([])
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .setLoading(let isLoading):
            state.isLoading = isLoading
        case .setSearching(let isSearching):
            state.isSearching = isSearching
        case .setSearchQuery(let query):
            state.searchQuery = query
            state.showAllTodos = false
            state.showAllWebPages = false
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                cancelDebounce()
                state.webPages = []
                state.todos = []
            } else {
                scheduleDebouncedQuery(query)
            }
        case .applySearchQuery(let query):
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                state.webPages = []
                state.todos = []
            } else {
                effects = [.fetch(trimmed)]
            }
        case .setShowAllTodos(let shouldShowAll):
            state.showAllTodos = shouldShowAll
        case .setShowAllWebPages(let shouldShowAll):
            state.showAllWebPages = shouldShowAll
        }

        self.state = state
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetch(let query):
            Task {
                do {
                    send(.setLoading(true))
                    defer { send(.setLoading(false)) }
                    async let todos = fetchTodosByKeywordUseCase.execute(query)
                    async let webPages = fetchWebPagesUseCase.execute(query)
                    let todoItems = try await todos.map { TodoListItem(from: $0) }
                    let webPageItems = try await webPages.map { WebPageItem(from: $0) }
                    send(.fetchTodos(todoItems))
                    send(.fetchWebPage(webPageItems))
                } catch {
                    send(.setAlert(true))
                }
            }
        }
    }
}

private extension SearchViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }

    func scheduleDebouncedQuery(_ query: String) {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(searchDebounceDelay))
            if Task.isCancelled { return }
            await MainActor.run {
                self.send(.applySearchQuery(query))
            }
        }
    }

    func cancelDebounce() {
        searchDebounceTask?.cancel()
        searchDebounceTask = nil
    }

    static func loadRecentQueries(userDefaults: UserDefaults) -> OrderedSet<String> {
        OrderedSet(userDefaults.stringArray(forKey: DefaultsKey.recentQueries) ?? [])
    }

    func saveRecentQueries(_ queries: OrderedSet<String>) {
        userDefaults.set(Array(queries), forKey: DefaultsKey.recentQueries)
    }
}
