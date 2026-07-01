//
//  HomeFeature.swift
//  Presentation
//
//  Created by opfic on 6/14/26.
//

import ComposableArchitecture
import Domain
import Foundation

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        @Presents var sheet: SheetState?
        @Presents var fullScreenCover: FullScreenCoverState?
        var preferences = [TodoCategoryItem]()
        var recentTodos = [RecentTodoItem]()
        var webPages = [WebPageItem]()
        var needsWebPageRefresh = false
        var isNetworkConnected = true
        var webPageURLInput = "https://"
        var selectedTodoCategory: TodoCategory?
        var deletedWebPage: DeletedWebPage?
        var loading = LoadingFeature.State()

        var showContentPicker: Bool { sheet?.contentPickerState != nil }
        var showTodoEditor: Bool {
            fullScreenCover?.destination == .todoEditor
        }

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

    struct DeletedWebPage: Equatable {
        let id: String
        let urlString: String
    }

    enum Action: Equatable {
        case alert(PresentationAction<Never>)
        case sheet(PresentationAction<Sheet>)
        case fullScreenCover(PresentationAction<FullScreenCover>)
        case view(ViewAction)
        case store(StoreAction)
        case loading(LoadingFeature.Action)

        enum ViewAction: Equatable {
            case startObserving
            case fetchData
            case refreshRecentTodos
            case refreshWebPages
            case finishDeleteWebPageToast(String)
            case tapTodoCategory(TodoCategory)
            case orderTodoCategory([TodoCategoryItem])
            case updateWebPageURLInput(String)
            case addWebPage
            case deleteWebPage(WebPageItem)
            case undoDeleteWebPage
        }

        enum StoreAction: Equatable {
            case networkStatusChanged(Bool)
            case setSheet(SheetState?)
            case setPresentation(Presentation, Bool)
            case setAlert(isPresented: Bool, type: AlertType? = nil)
            case setWebPageHidden(String, Bool)
            case handleWebPageDeleteFailure(String)
            case setTodoCategory([TodoCategoryItem])
            case updateRecentTodos([RecentTodoItem])
            case updateWebPages([WebPageItem])
        }
    }

    enum AlertType: Equatable {
        case invalidURL
        case error
    }

    @ObservableState
    struct ContentPickerState: Equatable {
        @Presents var webPageInput: WebPageInputState?
    }

    @ObservableState
    struct WebPageInputState: Equatable, Identifiable {
        let id = UUID()
    }

    @ObservableState
    @CasePathable
    enum SheetState: Equatable {
        case reorderTodo
        case contentPicker(ContentPickerState)

        var contentPickerState: ContentPickerState? {
            get {
                guard case .contentPicker(let state) = self else { return nil }
                return state
            }
            set {
                guard let newValue else { return }
                self = .contentPicker(newValue)
            }
        }
    }

    @CasePathable
    enum Sheet: Equatable {
        case tapCloseButton
        case contentPicker(ContentPicker)

        @CasePathable
        enum ContentPicker: Equatable {
            case tapWebPageInput
            case webPageInput(PresentationAction<Never>)
        }
    }

    @ObservableState
    struct FullScreenCoverState: Equatable {
        var destination: Destination
        var selectedTodoCategory: TodoCategory?
        var todoEditor: TodoEditorFeature.State?

        enum Destination: Equatable {
            case todoEditor
            case search
        }

        static func todoEditor(_ category: TodoCategory) -> Self {
            Self(
                destination: .todoEditor,
                selectedTodoCategory: category,
                todoEditor: TodoEditorFeature.State(category: category)
            )
        }

        static let search = Self(destination: .search)
    }

    @CasePathable
    enum FullScreenCover: Equatable {
        case todoEditor(TodoEditorFeature.Action)
    }

    enum Presentation: Equatable {
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
            case .alert:
                break
            case .fullScreenCover(.presented(.todoEditor(.delegate(.created)))):
                state.fullScreenCover = nil
                state.selectedTodoCategory = nil
                return .merge(
                    trackTodoCreateEffect(),
                    .send(.view(.fetchData))
                )
            case .fullScreenCover(.dismiss):
                state.fullScreenCover = nil
                state.selectedTodoCategory = nil
            case .fullScreenCover:
                break
            case .sheet(.dismiss), .sheet(.presented(.tapCloseButton)):
                state.sheet = nil
            case .sheet:
                break
            case .view(let action):
                return reduce(action, state: &state)
            case .store(let action):
                return reduce(action, state: &state)
            case .loading:
                break
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$sheet, action: \.sheet) {
            HomeSheetFeature()
        }
        .ifLet(\.$fullScreenCover, action: \.fullScreenCover) {
            HomeFullScreenCoverFeature()
        }
    }
}

private struct HomeFullScreenCoverFeature: Reducer {
    typealias State = HomeFeature.FullScreenCoverState
    typealias Action = HomeFeature.FullScreenCover

    var body: some ReducerOf<Self> {
        EmptyReducer()
            .ifLet(\.todoEditor, action: \.todoEditor) {
                TodoEditorFeature()
            }
    }
}

private extension HomeFeature {
    func reduce(
        _ action: Action.ViewAction,
        state: inout State
    ) -> Effect<Action> {
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
        case .refreshWebPages:
            return fetchWebPagesEffect()
        case .finishDeleteWebPageToast(let urlString):
            state.webPages.removeAll { $0.url.absoluteString == urlString && $0.isHidden }
            if state.deletedWebPage?.urlString == urlString {
                state.deletedWebPage = nil
            }
        case .tapTodoCategory(let category):
            state.selectedTodoCategory = category
            state.sheet = nil
            return delayedTodoEditorEffect()
        case .orderTodoCategory(let preferences):
            state.preferences = preferences
            state.recentTodos = Self.syncRecentTodos(state.recentTodos, preferences: preferences)
            state.sheet = nil
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
            state.deletedWebPage = DeletedWebPage(
                id: page.id,
                urlString: page.url.absoluteString
            )
            state.webPages[index].isHidden = true
            return deleteWebPageEffect(page)
        case .undoDeleteWebPage:
            guard let webPage = state.deletedWebPage else { return .none }
            if let index = state.webPages.firstIndex(where: { $0.id == webPage.id }) {
                state.webPages[index].isHidden = false
            }
            state.deletedWebPage = nil
            return undoDeleteWebPageEffect(webPage)
        }

        return .none
    }

    func reduce(
        _ action: Action.StoreAction,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .networkStatusChanged(let isConnected):
            state.isNetworkConnected = isConnected
        case .setSheet(let sheet):
            state.sheet = sheet
        case .setPresentation(let presentation, let isPresented):
            Self.setPresentation(&state, presentation: presentation, isPresented: isPresented)
        case .setAlert(let isPresented, let type):
            Self.setAlert(&state, isPresented: isPresented, type: type)
        case .setWebPageHidden(let id, let isHidden):
            if let index = state.webPages.firstIndex(where: { $0.id == id }) {
                state.webPages[index].isHidden = isHidden
            }
        case .handleWebPageDeleteFailure(let id):
            if let index = state.webPages.firstIndex(where: { $0.id == id }) {
                state.webPages[index].isHidden = false
            } else {
                state.needsWebPageRefresh = true
            }
        case .setTodoCategory(let preferences):
            state.preferences = preferences
            state.recentTodos = Self.syncRecentTodos(state.recentTodos, preferences: preferences)
        case .updateRecentTodos(let todos):
            state.recentTodos = todos
        case .updateWebPages(let pages):
            state.webPages = pages
            state.needsWebPageRefresh = false
        }

        return .none
    }
}

private struct HomeSheetFeature: Reducer {
    typealias State = HomeFeature.SheetState
    typealias Action = HomeFeature.Sheet

    var body: some ReducerOf<Self> {
        EmptyReducer()
        .ifCaseLet(\.contentPicker, action: \.contentPicker) {
            HomeContentPickerFeature()
        }
    }
}

private struct HomeContentPickerFeature: Reducer {
    typealias State = HomeFeature.ContentPickerState
    typealias Action = HomeFeature.Sheet.ContentPicker

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .tapWebPageInput:
                state.webPageInput = .init()
            case .webPageInput(.dismiss):
                state.webPageInput = nil
            case .webPageInput:
                break
            }

            return .none
        }
        .ifLet(\.$webPageInput, action: \.webPageInput) {
            HomeWebPageInputFeature()
        }
    }
}

private struct HomeWebPageInputFeature: Reducer {
    typealias State = HomeFeature.WebPageInputState
    typealias Action = Never

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}
