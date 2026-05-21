//
//  SearchViewModel.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 2/8/26.
//

import Foundation
import OrderedCollections
import DevLogCore
import DevLogDomain

@Observable
final class SearchViewModel: Store {
    struct State: Equatable {
        var isLoading: Bool = false
        var isSearching: Bool = false
        var searchQuery: String = ""
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
        case cancelSearch
        case debounceFetch(String)
        case fetch(String)
    }

    private enum SearchTaskKind: Hashable {
        case debounce
        case request
    }

    private(set) var state: State = .init()
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    private let fetchTodosUseCase: FetchTodosUseCase
    private let fetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase
    private let updateRecentSearchQueriesUseCase: UpdateRecentSearchQueriesUseCase
    private let loadingState = LoadingState()
    let contentsLimit: Int = 5

    private let maxRecentQueries = 20
    private let searchDebounceDelay: Double = 0.4
    private var searchTasks: [SearchTaskKind: Task<Void, Never>] = [:]

    init(
        fetchWebPagesUseCase: FetchWebPagesUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        fetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase,
        updateRecentSearchQueriesUseCase: UpdateRecentSearchQueriesUseCase
    ) {
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchRecentSearchQueriesUseCase = fetchRecentSearchQueriesUseCase
        self.updateRecentSearchQueriesUseCase = updateRecentSearchQueriesUseCase
        self.state.recentQueries = OrderedSet(fetchRecentSearchQueriesUseCase.execute())
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .fetchWebPage(let items):
            state.webPages = items
        case .fetchTodos(let items):
            state.todos = items
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
            if !isSearching {
                effects = [.cancelSearch]
            }
        case .setSearchQuery(let query):
            guard state.searchQuery != query else { return [] }
            state.searchQuery = query
            state.showAllTodos = false
            state.showAllWebPages = false
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                state.webPages = []
                state.todos = []
                effects = [.cancelSearch]
            } else {
                effects = [.cancelSearch, .debounceFetch(trimmed)]
            }
        case .applySearchQuery(let query):
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                state.webPages = []
                state.todos = []
                effects = [.cancelSearch]
            } else {
                effects = [.fetch(trimmed)]
            }
        case .setShowAllTodos(let shouldShowAll):
            state.showAllTodos = shouldShowAll
        case .setShowAllWebPages(let shouldShowAll):
            state.showAllWebPages = shouldShowAll
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .cancelSearch:
            cancelSearch()
        case .debounceFetch(let query):
            beginLoading(.immediate)
            scheduleDebouncedFetch(query)
        case .fetch(let query):
            searchTasks[.request]?.cancel()
            let requestTask = Task { [weak self] in
                guard let self else { return }
                do {
                    defer {
                        self.searchTasks[.request] = nil
                        if !Task.isCancelled {
                            self.endLoading(.immediate)
                        }
                    }
                    let searchesTodoOnly = searchesTodoOnly(query)
                    async let todos = fetchTodosUseCase.execute(TodoQuery(keyword: query), cursor: nil)
                    async let webPageItems = fetchWebPageItems(
                        query: query,
                        searchesTodoOnly: searchesTodoOnly
                    )
                    let todoItems = try await todos.items.compactMap { TodoListItem(from: $0) }
                    let resolvedWebPageItems = try await webPageItems
                    if Task.isCancelled { return }
                    send(.fetchTodos(todoItems))
                    send(.fetchWebPage(resolvedWebPageItems))
                } catch {
                    if error is CancellationError { return }
                    send(.setAlert(true))
                }
            }
            searchTasks[.request] = requestTask
        }
    }
}

private extension SearchViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }

    func scheduleDebouncedFetch(_ query: String) {
        searchTasks[.debounce]?.cancel()
        let debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(searchDebounceDelay))
            if Task.isCancelled { return }
            await MainActor.run {
                self.searchTasks[.debounce] = nil
                self.send(.applySearchQuery(query))
            }
        }
        searchTasks[.debounce] = debounceTask
    }

    func cancelSearch() {
        searchTasks.values.forEach { $0.cancel() }
        searchTasks = [:]
        endLoading(.immediate)
    }

    func beginLoading(_ mode: LoadingState.Mode) {
        loadingState.begin(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    func endLoading(_ mode: LoadingState.Mode) {
        loadingState.end(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    func searchesTodoOnly(_ query: String) -> Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("#")
    }

    func fetchWebPageItems(
        query: String,
        searchesTodoOnly: Bool
    ) async throws -> [WebPageItem] {
        if searchesTodoOnly {
            return []
        }

        let webPages = try await fetchWebPagesUseCase.execute(query)
        return webPages.map { WebPageItem(from: $0) }
    }

    func saveRecentQueries(_ queries: OrderedSet<String>) {
        updateRecentSearchQueriesUseCase.execute(Array(queries))
    }
}
