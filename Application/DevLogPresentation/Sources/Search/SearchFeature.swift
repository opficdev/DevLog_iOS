//
//  SearchFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/12/26.
//

import ComposableArchitecture
import Foundation
import OrderedCollections
import DevLogCore
import DevLogDomain

@Reducer
struct SearchFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        var isLoading = false
        var isSearching = false
        var searchQuery = ""
        var webPages: [WebPageItem] = []
        var todos: [TodoListItem] = []
        var recentQueries = OrderedSet<String>()
        var showAllTodos = false
        var showAllWebPages = false
        let contentsLimit = 5

        init(recentQueries: [String] = []) {
            self.recentQueries = OrderedSet(recentQueries)
        }

        var visibleTodos: [TodoListItem] {
            if showAllTodos {
                return todos
            }

            return Array(todos.prefix(contentsLimit))
        }

        var visibleWebPages: [WebPageItem] {
            if showAllWebPages {
                return webPages
            }

            return Array(webPages.prefix(contentsLimit))
        }

        var shouldShowMoreTodos: Bool {
            !showAllTodos && contentsLimit < todos.count
        }

        var shouldShowMoreWebPages: Bool {
            !showAllWebPages && contentsLimit < webPages.count
        }
    }

    enum Action: Equatable {
        case alert(PresentationAction<Never>)
        case fetchWebPage([WebPageItem])
        case fetchTodos([TodoListItem])
        case addRecentQuery(String)
        case removeRecentQuery(String)
        case clearRecentQueries
        case applySearchQuery(String)
        case setAlert(Bool)
        case setLoading(Bool)
        case setSearching(Bool)
        case setSearchQuery(String)
        case setShowAllTodos(Bool)
        case setShowAllWebPages(Bool)
    }

    private enum CancelID: Hashable {
        case debounce
        case request
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.searchFetchTodosUseCase) var fetchTodosUseCase
    @Dependency(\.searchFetchWebPagesUseCase) var fetchWebPagesUseCase
    @Dependency(\.searchUpdateRecentQueriesUseCase) var updateRecentSearchQueriesUseCase

    private let maxRecentQueries = 20
    private let searchDebounceDelay = Duration.seconds(0.4)

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert:
                break
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
                return saveRecentQueriesEffect(state.recentQueries)
            case .removeRecentQuery(let query):
                state.recentQueries.remove(query)
                return saveRecentQueriesEffect(state.recentQueries)
            case .clearRecentQueries:
                state.recentQueries = []
                return saveRecentQueriesEffect([])
            case .applySearchQuery(let query):
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    state.webPages = []
                    state.todos = []
                    return cancelSearchEffect()
                } else {
                    return fetchEffect(trimmed)
                }
            case .setAlert(let isPresented):
                state.alert = isPresented ? alertState() : nil
            case .setLoading(let isLoading):
                state.isLoading = isLoading
            case .setSearching(let isSearching):
                state.isSearching = isSearching
                if !isSearching {
                    return cancelSearchEffect()
                }
            case .setSearchQuery(let query):
                guard state.searchQuery != query else { return .none }
                state.searchQuery = query
                state.showAllTodos = false
                state.showAllWebPages = false
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    state.webPages = []
                    state.todos = []
                    return cancelSearchEffect()
                } else {
                    return .concatenate(
                        cancelSearchEffect(),
                        debounceFetchEffect(trimmed)
                    )
                }
            case .setShowAllTodos(let shouldShowAll):
                state.showAllTodos = shouldShowAll
            case .setShowAllWebPages(let shouldShowAll):
                state.showAllWebPages = shouldShowAll
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }

}

extension DependencyValues {
    var searchFetchTodosUseCase: FetchTodosUseCase {
        get { self[SearchFetchTodosUseCaseKey.self] }
        set { self[SearchFetchTodosUseCaseKey.self] = newValue }
    }

    var searchFetchWebPagesUseCase: FetchWebPagesUseCase {
        get { self[SearchFetchWebPagesUseCaseKey.self] }
        set { self[SearchFetchWebPagesUseCaseKey.self] = newValue }
    }

    var searchUpdateRecentQueriesUseCase: UpdateRecentSearchQueriesUseCase {
        get { self[SearchUpdateRecentQueriesUseCaseKey.self] }
        set { self[SearchUpdateRecentQueriesUseCaseKey.self] = newValue }
    }
}

private enum SearchFetchTodosUseCaseKey: DependencyKey {
    static var liveValue: FetchTodosUseCase {
        preconditionFailure("FetchTodosUseCase must be provided.")
    }

    static var testValue: FetchTodosUseCase {
        liveValue
    }
}

private enum SearchFetchWebPagesUseCaseKey: DependencyKey {
    static var liveValue: FetchWebPagesUseCase {
        preconditionFailure("FetchWebPagesUseCase must be provided.")
    }

    static var testValue: FetchWebPagesUseCase {
        liveValue
    }
}

private enum SearchUpdateRecentQueriesUseCaseKey: DependencyKey {
    static var liveValue: UpdateRecentSearchQueriesUseCase {
        preconditionFailure("UpdateRecentSearchQueriesUseCase must be provided.")
    }

    static var testValue: UpdateRecentSearchQueriesUseCase {
        liveValue
    }
}

private extension SearchFeature {
    func cancelSearchEffect() -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.debounce),
            .cancel(id: CancelID.request),
            .send(.setLoading(false))
        )
    }

    func debounceFetchEffect(_ query: String) -> Effect<Action> {
        .concatenate(
            .send(.setLoading(true)),
            .run { [clock, searchDebounceDelay] send in
                try await clock.sleep(for: searchDebounceDelay)
                await send(.applySearchQuery(query))
            }
            .cancellable(id: CancelID.debounce, cancelInFlight: true)
        )
    }

    func fetchEffect(_ query: String) -> Effect<Action> {
        let searchesTodoOnly = searchesTodoOnly(query)

        return .run { [fetchTodosUseCase, fetchWebPagesUseCase] send in
            do {
                async let todos = fetchTodosUseCase.execute(TodoQuery(keyword: query), cursor: nil)
                async let webPageItems = fetchWebPageItems(
                    query: query,
                    searchesTodoOnly: searchesTodoOnly,
                    fetchWebPagesUseCase: fetchWebPagesUseCase
                )
                let todoItems = try await todos.items.compactMap { TodoListItem(from: $0) }
                let resolvedWebPageItems = try await webPageItems
                await send(.fetchTodos(todoItems))
                await send(.fetchWebPage(resolvedWebPageItems))
                await send(.setLoading(false))
            } catch is CancellationError {
                return
            } catch {
                await send(.setLoading(false))
                await send(.setAlert(true))
            }
        }
        .cancellable(id: CancelID.request, cancelInFlight: true)
    }

    func saveRecentQueriesEffect(_ queries: OrderedSet<String>) -> Effect<Action> {
        let values = Array(queries)
        return .run { [updateRecentSearchQueriesUseCase] _ in
            updateRecentSearchQueriesUseCase.execute(values)
        }
    }

    func searchesTodoOnly(_ query: String) -> Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("#")
    }

    func fetchWebPageItems(
        query: String,
        searchesTodoOnly: Bool,
        fetchWebPagesUseCase: FetchWebPagesUseCase
    ) async throws -> [WebPageItem] {
        if searchesTodoOnly {
            return []
        }

        let webPages = try await fetchWebPagesUseCase.execute(query)
        return webPages.map { WebPageItem(from: $0) }
    }

    func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close"))
            }
        } message: {
            TextState(String(localized: "common_error_message"))
        }
    }
}
