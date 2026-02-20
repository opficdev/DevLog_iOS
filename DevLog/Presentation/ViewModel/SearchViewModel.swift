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
        var filteredWebPages: [WebPageItem] = []
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
        case applySearchQuery(String)   // 뷰모델에서 쿼리에 대해 디바운스 적용
        case setAlert(Bool)
        case setLoading(Bool)
        case setSearching(Bool)
        case setSearchQuery(String) // 뷰에서 쿼리 입력을 적용
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
    private let searchDebounceDelay: Double = 0.4
    private var searchDebounceTask: Task<Void, Never>?

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
            applyFilter(&state, query: state.searchQuery)
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
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                cancelDebounce()
                applyFilter(&state, query: "")
            } else {
                scheduleDebouncedQuery(query)
            }
        case .applySearchQuery(let query):
            applyFilter(&state, query: query)
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

    func applyFilter(_ state: inout State, query: String) {
        state.filteredWebPages = state.webPages.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.displayURL.localizedCaseInsensitiveContains(query)
        }
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

    func saveRecentQueries(_ queries: [String]) {
        userDefaults.set(queries, forKey: DefaultsKey.recentQueries)
    }
}
