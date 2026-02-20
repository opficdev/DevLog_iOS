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
        var webPages: OrderedSet<WebPageItem> = []
        var recentQueries: OrderedSet<String> = []
        var filteredWebPages: [WebPageItem] {
            webPages.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.displayURL.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }

    enum Action {
        case onAppear
        case fetchWebPage([WebPageItem]? = nil)
        case selectWebPage(WebPageItem)
        case addRecentQuery(String)
        case removeRecentQuery(String)
        case clearRecentQueries
        case setAlert(Bool)
        case setLoading(Bool)
        case setSearching(Bool)
        case setSearchQuery(String)
    }

    enum SideEffect {
        case fetch
    }

    @Published private(set) var state: State = .init()
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    private let userDefaults: UserDefaults

    private enum DefaultsKey {
        static let recentQueries = "Search.recentQueries"
    }

    private let maxRecentQueries = 20

    init(
        fetchWebPagesUseCase: FetchWebPagesUseCase,
        userDefaults: UserDefaults = .standard
    ) {
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
        self.userDefaults = userDefaults
        self.state.recentQueries = Self.loadRecentQueries(userDefaults: userDefaults)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .onAppear:
            state.isSearching = true
            self.state = state
            return [.fetch]
        case .fetchWebPage(let items):
            guard let items else {
                self.state = state
                return [.fetch]
            }
            state.webPages = OrderedSet(items)
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
            saveRecentQueries(Array(state.recentQueries))
        case .removeRecentQuery(let query):
            state.recentQueries.remove(query)
            saveRecentQueries(Array(state.recentQueries))
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
        }

        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetch:
            Task {
                do {
                    send(.setLoading(true))
                    defer { send(.setLoading(false)) }
                    let items = try await self.fetchWebPagesUseCase.execute().map { WebPageItem(from: $0) }
                    send(.fetchWebPage(items))
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

    static func loadRecentQueries(userDefaults: UserDefaults) -> OrderedSet<String> {
        OrderedSet(userDefaults.stringArray(forKey: DefaultsKey.recentQueries) ?? [])
    }

    func saveRecentQueries(_ queries: [String]) {
        userDefaults.set(queries, forKey: DefaultsKey.recentQueries)
    }
}
