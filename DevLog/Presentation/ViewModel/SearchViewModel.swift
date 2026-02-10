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
        var alertMsg: String = ""
        var isLoading: Bool = false
        var isSearching: Bool = false
        var newURL: String = "https://"
        var searchQuery: String = ""
        var selectedWebPage: WebPageItem?
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
        var webPages: OrderedSet<WebPageItem> = []
        var filteredWebPages: [WebPageItem] {
            if searchQuery.isEmpty {
                // TODO: 자주 방문한 것을 보여주는 기능으로 변경 필요
                return []
            } else {
                return webPages.filter {
                    $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                    $0.displayURL.localizedCaseInsensitiveContains(searchQuery)
                }
            }
        }
    }

    enum Action {
        case addWebPage(WebPageItem? = nil)
        case deleteWebPage(item: WebPageItem, fromEffect: Bool = false)
        case fetchWebPage([WebPageItem]? = nil)
        case selectWebPage(WebPageItem)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setLoading(Bool)
        case setNewURL(String = "https://")
        case setSearching(Bool)
        case setSearchQuery(String)
    }

    enum SideEffect {
        case fetch
        case add(String)
        case delete(WebPageItem)
    }

    enum AlertType {
        case addWebPage, error
    }

    @Published private(set) var state: State = .init()
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    private let addWebPageUseCase: AddWebPageUseCase
    private let deleteWebPageUseCase: DeleteWebPageUseCase

    init(
        fetchWebPagesUseCase: FetchWebPagesUseCase,
        addWebPageUseCase: AddWebPageUseCase,
        deleteWebPageUseCase: DeleteWebPageUseCase
    ) {
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
        self.addWebPageUseCase = addWebPageUseCase
        self.deleteWebPageUseCase = deleteWebPageUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .addWebPage(let item):
            guard let item else { return [.add(state.newURL)] }
            state.webPages.append(item)
        case .deleteWebPage(let info, let fromEffect):
            if !fromEffect { return [.delete(info)] }
            state.webPages.removeAll { $0.url == info.url }
        case .fetchWebPage(let items):
            guard let items else { return [.fetch] }
            state.webPages = OrderedSet(items)
        case .selectWebPage(let newValue):
            state.selectedWebPage = newValue
        case .setAlert(let isPresented, let type):
            setAlert(isPresented: isPresented, for: type)
            return []
        case .setLoading(let newValue):
            state.isLoading = newValue
        case .setNewURL(let newValue):
            state.newURL = newValue
        case .setSearching(let newValue):
            state.isSearching = newValue
        case .setSearchQuery(let newValue):
            state.searchQuery = newValue
        }

        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetch:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let items = try await fetchWebPagesUseCase.execute().map { WebPageItem(from: $0) }
                    send(.fetchWebPage(items))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .add(let urlString):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let metadata = try await addWebPageUseCase.execute(urlString)
                    let item = WebPageItem(from: metadata)
                    send(.addWebPage(item))
                    send(.setNewURL())
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .delete(let item):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))

                    try await deleteWebPageUseCase.execute(item.url.absoluteString)
                    send(.deleteWebPage(item: item, fromEffect: true))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        }
    }
}

private extension SearchViewModel {
    func setAlert(isPresented: Bool, for type: AlertType?) {
        switch type {
        case .addWebPage:
            state.alertTitle = "웹 페이지 추가"
            state.alertMessage = ""
        case .error:
            state.alertTitle = "오류"
            state.alertMessage = "문제가 발생했습니다. 잠시 다시 시도해주세요."
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }
        state.alertType = type
        state.showAlert = isPresented
    }
}
