//
//  SearchFeatureTestDoubles.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/12/26.
//

import ComposableArchitecture
import Foundation
import OrderedCollections
import DevLogCore
import DevLogDomain
@testable import DevLogPresentation

@MainActor
struct SearchStoreTestAdapter {
    private let store: TestStoreOf<SearchFeature>

    var searchQuery: String { store.state.searchQuery }
    var isSearching: Bool { store.state.isSearching }
    var isLoading: Bool { store.state.isLoading }
    var todos: [TodoListItem] { store.state.todos }
    var webPages: [WebPageItem] { store.state.webPages }
    var recentQueries: [String] { Array(store.state.recentQueries) }
    var showAllTodos: Bool { store.state.showAllTodos }
    var showAllWebPages: Bool { store.state.showAllWebPages }
    var alert: AlertState<Never>? { store.state.alert }

    init(
        recentQueries: [String] = [],
        initialTodos: [TodoListItem] = [],
        initialWebPages: [WebPageItem] = [],
        isSearching: Bool = false,
        isLoading: Bool = false,
        fetchWebPagesUseCase: FetchWebPagesUseCase = SearchFetchWebPagesUseCaseSpy(),
        fetchTodosUseCase: FetchTodosUseCase = SearchFetchTodosUseCaseSpy(),
        updateRecentQueriesUseCase: UpdateRecentSearchQueriesUseCase = SearchUpdateRecentQueriesUseCaseSpy(),
        configureDependencies: ((inout DependencyValues) -> Void)? = nil
    ) {
        var state = SearchFeature.State(recentQueries: recentQueries)
        state.todos = initialTodos
        state.webPages = initialWebPages
        state.isSearching = isSearching
        state.isLoading = isLoading
        store = TestStore(initialState: state) {
            SearchFeature()
        } withDependencies: {
            $0.searchFetchWebPagesUseCase = fetchWebPagesUseCase
            $0.searchFetchTodosUseCase = fetchTodosUseCase
            $0.searchUpdateRecentQueriesUseCase = updateRecentQueriesUseCase
            $0.continuousClock = ContinuousClock()
            configureDependencies?(&$0)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func addRecentQuery(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxRecentQueries = 20
        await store.send(.addRecentQuery(query)) {
            guard !trimmed.isEmpty else { return }
            $0.recentQueries.remove(trimmed)
            $0.recentQueries.insert(trimmed, at: 0)
            if maxRecentQueries < $0.recentQueries.count {
                $0.recentQueries = OrderedSet($0.recentQueries.prefix(maxRecentQueries))
            }
        }
    }

    func removeRecentQuery(_ query: String) async {
        await store.send(.removeRecentQuery(query)) {
            $0.recentQueries.remove(query)
        }
    }

    func clearRecentQueries() async {
        await store.send(.clearRecentQueries) {
            $0.recentQueries = []
        }
    }

    func setShowAllTodos(_ value: Bool) async {
        await store.send(.setShowAllTodos(value)) {
            $0.showAllTodos = value
        }
    }

    func setShowAllWebPages(_ value: Bool) async {
        await store.send(.setShowAllWebPages(value)) {
            $0.showAllWebPages = value
        }
    }

    func setSearchQuery(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        await store.send(.setSearchQuery(query)) {
            $0.searchQuery = query
            $0.showAllTodos = false
            $0.showAllWebPages = false
            if trimmed.isEmpty {
                $0.todos = []
                $0.webPages = []
            }
        }
        await store.receive(.setLoading(false)) {
            $0.isLoading = false
        }
        if !trimmed.isEmpty {
            await store.receive(.setLoading(true)) {
                $0.isLoading = true
            }
        }
    }

    func applySearchQuery(_ query: String) async {
        await store.send(.applySearchQuery(query))
    }

    func setSearching(_ value: Bool) async {
        await store.send(.setSearching(value)) {
            $0.isSearching = value
        }
        if !value {
            await store.receive(.setLoading(false)) {
                $0.isLoading = false
            }
        }
    }

    func receiveAppliedSearchQuery(_ query: String) async {
        await store.receive(.applySearchQuery(query))
    }

    func receiveSearchResults(
        todos: [TodoListItem],
        webPages: [WebPageItem]
    ) async {
        await store.receive(.fetchTodos(todos)) {
            $0.todos = todos
        }
        await store.receive(.fetchWebPage(webPages)) {
            $0.webPages = webPages
        }
        await store.receive(.setLoading(false)) {
            $0.isLoading = false
        }
    }

    func receiveSearchFailure() async {
        await store.receive(.setLoading(false)) {
            $0.isLoading = false
        }
        await store.receive(.setAlert(true)) {
            $0.alert = expectedSearchErrorAlert()
        }
    }
}

final class SearchFetchTodosUseCaseSpy: FetchTodosUseCase {
    var page: TodoPage
    var error: Error?
    private(set) var queries = [TodoQuery]()

    init(page: TodoPage = TodoPage(items: [], nextCursor: nil)) {
        self.page = page
    }

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)

        if let error {
            throw error
        }

        return page
    }
}

final class SearchFetchWebPagesUseCaseSpy: FetchWebPagesUseCase {
    var webPages: [WebPage]
    var error: Error?
    private(set) var queries = [String]()

    init(webPages: [WebPage] = []) {
        self.webPages = webPages
    }

    func execute(_ query: String) async throws -> [WebPage] {
        queries.append(query)

        if let error {
            throw error
        }

        return webPages
    }
}

final class SearchUpdateRecentQueriesUseCaseSpy: UpdateRecentSearchQueriesUseCase {
    private(set) var queries = [[String]]()

    func execute(_ queries: [String]) {
        self.queries.append(queries)
    }
}

enum SearchFeatureTestError: Error {
    case failure
}

func makeSearchTodo(
    id: String = "todo-id",
    title: String = "Todo"
) -> Todo {
    Todo(
        id: id,
        isPinned: false,
        isCompleted: false,
        isChecked: false,
        number: 1,
        title: title,
        content: "content",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0),
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: .system(.feature)
    )
}

func makeSearchWebPage(
    title: String? = "Web",
    urlString: String = "https://example.com"
) -> WebPage {
    let url = URL(string: urlString)!
    return WebPage(
        title: title,
        url: url,
        displayURL: url,
        imageURL: nil
    )
}

func expectedSearchErrorAlert() -> AlertState<Never> {
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
