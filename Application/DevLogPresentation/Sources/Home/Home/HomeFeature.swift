//
//  HomeFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/14/26.
//

import Combine
import ComposableArchitecture
import DevLogDomain
import Foundation

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var preferences = [TodoCategoryItem]()
        var recentTodos = [RecentTodoItem]()
        var webPages = [WebPageItem]()
        var needsWebPageRefresh = false
        var isNetworkConnected = true
        var showContentPicker = false
        var showTodoEditor = false
        var showSearchView = false
        var webPageURLInput = "https://"
        var selectedTodoCategory: TodoCategory?
        var reorderTodo = false
        var showAlert = false
        var alertTitle = ""
        var alertType: AlertType?
        var alertMessage = ""
        var deletedWebPageURLString: String?
        var loading = LoadingFeature.State()

        var isPreferencesLoading: Bool {
            loading.visibleTargets.contains(LoadingTarget.preferences.target)
        }

        var isRecentTodosLoading: Bool {
            loading.visibleTargets.contains(LoadingTarget.recentTodos.target)
        }

        var isWebPageLoading: Bool {
            loading.visibleTargets.contains(LoadingTarget.webPage.target)
        }

        var isAppending: Bool {
            loading.visibleTargets.contains(LoadingTarget.overlay.target)
        }
    }

    enum Action: Equatable {
        case startObserving
        case fetchData
        case refreshRecentTodos
        case networkStatusChanged(Bool)
        case setPresentation(Presentation, Bool)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case refreshWebPages
        case setWebPageHidden(URL, Bool)
        case handleWebPageDeleteFailure(URL)
        case finishDeleteWebPageToast(String)
        case tapTodoCategory(TodoCategory)
        case orderTodoCategory([TodoCategoryItem])
        case updateWebPageURLInput(String)
        case addWebPage
        case deleteWebPage(WebPageItem)
        case undoDeleteWebPage
        case store(StoreAction)
        case loading(LoadingFeature.Action)

        enum StoreAction: Equatable {
            case setTodoCategory([TodoCategoryItem])
            case updateRecentTodos([RecentTodoItem])
            case updateWebPages([WebPageItem])
        }
    }

    enum AlertType: Equatable {
        case webPageInput
        case invalidURL
        case error
    }

    enum ModalType: Hashable {
        case todoEditor
        case urlInputAlert
    }

    enum Presentation: Equatable {
        case reorderTodo
        case todoEditor
        case contentPicker
        case searchView
    }

    enum LoadingTarget: Hashable {
        case preferences
        case recentTodos
        case webPage
        case overlay

        var target: LoadingFeature.Target {
            switch self {
            case .preferences:
                return LoadingFeature.Target("home.preferences")
            case .recentTodos:
                return LoadingFeature.Target("home.recentTodos")
            case .webPage:
                return LoadingFeature.Target("home.webPage")
            case .overlay:
                return LoadingFeature.Target("home.overlay")
            }
        }
    }

    @Dependency(\.fetchTodoCategoryPreferencesUseCase) var fetchPreferencesUseCase
    @Dependency(\.homeUpdateTodoCategoryPreferencesUseCase) var updatePreferencesUseCase
    @Dependency(\.homeAddWebPageUseCase) var addWebPageUseCase
    @Dependency(\.homeDeleteWebPageUseCase) var deleteWebPageUseCase
    @Dependency(\.homeUndoDeleteWebPageUseCase) var undoDeleteWebPageUseCase
    @Dependency(\.homeFetchTodosUseCase) var fetchTodosUseCase
    @Dependency(\.homeFetchWebPagesUseCase) var fetchWebPagesUseCase
    @Dependency(\.networkConnectivityUseCase) var networkConnectivityUseCase
    @Dependency(\.trackAnalyticsEventUseCase) var trackAnalyticsEventUseCase
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        Reduce { state, action in
            switch action {
            case .startObserving:
                return observeNetworkConnectivityEffect()
            case .fetchData:
                return .merge(
                    fetchTodoCategoryPreferencesEffect(),
                    fetchRecentTodosEffect(),
                    fetchWebPagesEffect()
                )
            case .refreshRecentTodos:
                return fetchRecentTodosEffect()
            case .networkStatusChanged(let isConnected):
                state.isNetworkConnected = isConnected
            case .setPresentation(let presentation, let isPresented):
                Self.setPresentation(&state, presentation: presentation, isPresented: isPresented)
            case .setAlert(let isPresented, let type):
                if isPresented, type == .webPageInput, state.showContentPicker {
                    state.showContentPicker = false
                    return delayedModalEffect(.urlInputAlert)
                }
                Self.setAlert(&state, isPresented: isPresented, type: type)
            case .refreshWebPages:
                return fetchWebPagesEffect()
            case .setWebPageHidden(let webPageURL, let isHidden):
                if let index = state.webPages.firstIndex(where: { $0.id == webPageURL }) {
                    state.webPages[index].isHidden = isHidden
                }
            case .handleWebPageDeleteFailure(let webPageURL):
                if let index = state.webPages.firstIndex(where: { $0.id == webPageURL }) {
                    state.webPages[index].isHidden = false
                } else {
                    state.needsWebPageRefresh = true
                }
            case .finishDeleteWebPageToast(let urlString):
                state.webPages.removeAll { $0.url.absoluteString == urlString && $0.isHidden }
                if state.deletedWebPageURLString == urlString {
                    state.deletedWebPageURLString = nil
                }
            case .tapTodoCategory(let category):
                state.selectedTodoCategory = category
                state.showContentPicker = false
                return delayedModalEffect(.todoEditor)
            case .orderTodoCategory(let preferences):
                state.preferences = preferences
                state.recentTodos = Self.syncRecentTodos(state.recentTodos, preferences: preferences)
                return updateTodoCategoryPreferencesEffect(preferences)
            case .updateWebPageURLInput(let text):
                state.webPageURLInput = text
            case .addWebPage:
                guard let normalizedURL = Self.normalizedWebPageURL(state.webPageURLInput) else {
                    Self.setAlert(&state, isPresented: true, type: .invalidURL)
                    return .none
                }
                Self.setAlert(&state, isPresented: false, type: nil)
                return addWebPageEffect(normalizedURL)
            case .deleteWebPage(let page):
                guard let index = state.webPages.firstIndex(where: { $0.id == page.id }) else {
                    return .none
                }
                state.deletedWebPageURLString = page.url.absoluteString
                state.webPages[index].isHidden = true
                return deleteWebPageEffect(page)
            case .undoDeleteWebPage:
                guard let urlString = state.deletedWebPageURLString else { return .none }
                if let index = state.webPages.firstIndex(where: { $0.url.absoluteString == urlString }) {
                    state.webPages[index].isHidden = false
                }
                state.deletedWebPageURLString = nil
                return undoDeleteWebPageEffect(urlString)
            case .store(.setTodoCategory(let preferences)):
                state.preferences = preferences
                state.recentTodos = Self.syncRecentTodos(state.recentTodos, preferences: preferences)
            case .store(.updateRecentTodos(let todos)):
                state.recentTodos = todos
            case .store(.updateWebPages(let pages)):
                state.webPages = pages
                state.needsWebPageRefresh = false
            case .loading:
                break
            }

            return .none
        }
    }
}
