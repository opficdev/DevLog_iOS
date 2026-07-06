//
//  SearchFeature.swift
//  Presentation
//
//  Created by opfic on 6/12/26.
//

import Foundation
import Core
import Domain
import PresentationShared

@Reducer
public struct SearchFeature {
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Never>?
        public var loading = LoadingFeature.State()
        public var isSearching = false
        public var searchQuery = ""
        public var webPages: [WebPageItem] = []
        public var todos: [TodoListItem] = []
        public var recentQueries = OrderedSet<String>()
        public var showAllTodos = false
        public var showAllWebPages = false
        let contentsLimit = 5

        public init(recentQueries: [String] = []) {
            self.recentQueries = OrderedSet(recentQueries)
        }

        public var isLoading: Bool {
            loading.isLoading
        }

        public var visibleTodos: [TodoListItem] {
            if showAllTodos {
                return todos
            }

            return Array(todos.prefix(contentsLimit))
        }

        public var visibleWebPages: [WebPageItem] {
            if showAllWebPages {
                return webPages
            }

            return Array(webPages.prefix(contentsLimit))
        }

        public var shouldShowMoreTodos: Bool {
            !showAllTodos && contentsLimit < todos.count
        }

        public var shouldShowMoreWebPages: Bool {
            !showAllWebPages && contentsLimit < webPages.count
        }

        public var isHashOnlyQuery: Bool {
            searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == "#"
        }
    }

    public enum Action: BindableAction, Equatable {
        case onAppear
        case alert(PresentationAction<Never>)
        case binding(BindingAction<State>)
        case addRecentQuery(String)
        case removeRecentQuery(String)
        case clearRecentQueries
        case setShowAllTodos(Bool)
        case setShowAllWebPages(Bool)
        case store(StoreAction)
        case loading(LoadingFeature.Action)

        public enum StoreAction: Equatable {
            case fetchWebPage([WebPageItem])
            case fetchTodos([TodoListItem])
            case applySearchQuery(String)
            case setAlert(Bool)
        }
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

    public init() { }

    public var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    // `.searchable` 바인딩이 화면에 붙은 뒤 포커스를 요청하도록 main queue 다음 턴으로 넘긴다.
                    await withCheckedContinuation { continuation in
                        DispatchQueue.main.async { continuation.resume() }
                    }
                    await send(.binding(.set(\.isSearching, true)))
                }
            case .alert:
                break
            case .binding(\.isSearching):
                if !state.isSearching {
                    return Self.cancelSearchEffect(isLoading: state.isLoading)
                }
            case .binding(\.searchQuery):
                state.showAllTodos = false
                state.showAllWebPages = false
                let trimmed = state.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed == "#" {
                    state.webPages = []
                    state.todos = []
                    return Self.cancelSearchEffect(isLoading: state.isLoading)
                } else {
                    return .concatenate(
                        Self.cancelSearchEffect(isLoading: state.isLoading),
                        debounceFetchEffect(trimmed)
                    )
                }
            case .binding:
                break
            case .store(.fetchWebPage(let items)):
                state.webPages = items
            case .store(.fetchTodos(let items)):
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
            case .store(.applySearchQuery(let query)):
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed == "#" {
                    state.webPages = []
                    state.todos = []
                    return Self.cancelSearchEffect(isLoading: state.isLoading)
                } else {
                    return fetchEffect(trimmed, isLoading: state.isLoading)
                }
            case .store(.setAlert(let isPresented)):
                state.alert = isPresented ? Self.alertState() : nil
            case .setShowAllTodos(let shouldShowAll):
                state.showAllTodos = shouldShowAll
            case .setShowAllWebPages(let shouldShowAll):
                state.showAllWebPages = shouldShowAll
            case .loading:
                break
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

public extension DependencyValues {
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
    static func cancelSearchEffect(isLoading: Bool) -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.debounce),
            .cancel(id: CancelID.request),
            Self.endLoadingEffect(isLoading: isLoading)
        )
    }

    func debounceFetchEffect(_ query: String) -> Effect<Action> {
        .concatenate(
            .send(.loading(.begin(target: .default, mode: .immediate))),
            .run { [clock, searchDebounceDelay] send in
                try await clock.sleep(for: searchDebounceDelay)
                await send(.store(.applySearchQuery(query)))
            }
            .cancellable(id: CancelID.debounce, cancelInFlight: true)
        )
    }

    func fetchEffect(_ query: String, isLoading: Bool) -> Effect<Action> {
        let skipsWebPages = query.hasPrefix("#")

        return .run { [fetchTodosUseCase, fetchWebPagesUseCase] send in
            do {
                async let todos = fetchTodosUseCase.execute(TodoQuery(keyword: query), cursor: nil)
                let webPages = skipsWebPages ? [] : try await fetchWebPagesUseCase.execute(query)
                let todoItems = try await todos.items.compactMap { TodoListItem(from: $0) }
                let webPageItems = webPages.map { WebPageItem(from: $0) }
                await send(.store(.fetchTodos(todoItems)))
                await send(.store(.fetchWebPage(webPageItems)))
                if isLoading {
                    await send(.loading(.end(target: .default, mode: .immediate)))
                }
            } catch is CancellationError {
                return
            } catch {
                if isLoading {
                    await send(.loading(.end(target: .default, mode: .immediate)))
                }
                await send(.store(.setAlert(true)))
            }
        }
        .cancellable(id: CancelID.request, cancelInFlight: true)
    }

    static func endLoadingEffect(isLoading: Bool) -> Effect<Action> {
        guard isLoading else { return .none }
        return .send(.loading(.end(target: .default, mode: .immediate)))
    }

    func saveRecentQueriesEffect(_ queries: OrderedSet<String>) -> Effect<Action> {
        let values = Array(queries)
        return .run { [updateRecentSearchQueriesUseCase] _ in
            updateRecentSearchQueriesUseCase.execute(values)
        }
    }

    static func alertState() -> AlertState<Never> {
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
