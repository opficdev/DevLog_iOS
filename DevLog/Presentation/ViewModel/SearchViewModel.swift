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
        var filteredWebPages: [WebPageItem] {
            webPages.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.displayURL.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    enum Action {
        case onAppear
        case fetchWebPage([WebPageItem]? = nil)
        case selectWebPage(WebPageItem)
        case setLoading(Bool)
        case setSearching(Bool)
        case setSearchQuery(String)
    }

    enum SideEffect {
        case fetch
    }

    @Published private(set) var state: State = .init()
    private let fetchWebPagesUseCase: FetchWebPagesUseCase

    init(fetchWebPagesUseCase: FetchWebPagesUseCase) {
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
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

                }
            }
        }
    }
}
