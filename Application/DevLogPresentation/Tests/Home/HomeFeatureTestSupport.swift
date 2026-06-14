//
//  HomeFeatureTestSupport.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Combine
import ComposableArchitecture
import DevLogCore
import DevLogDomain
@testable import DevLogPresentation

@MainActor
protocol HomeStateDriving {
    var preferences: [TodoCategoryItem] { get }
    var recentTodos: [RecentTodoItem] { get }
    var webPages: [WebPageItem] { get }
    var isNetworkConnected: Bool { get }
    var showContentPicker: Bool { get }
    var showWebPageInputNavigation: Bool { get }
    var showTodoEditor: Bool { get }
    var showAlert: Bool { get }
    var alertType: HomeFeature.AlertType? { get }
    var alertTitle: String { get }
    var webPageURLInput: String { get }

    func startObserving() async
    func fetchData() async
    func openWebPageInput() async
    func setPresentation(_ presentation: HomeFeature.Presentation, _ isPresented: Bool) async
    func setAlert(isPresented: Bool, type: HomeFeature.AlertType?) async
    func tapTodoCategory(_ category: TodoCategory) async
    func orderTodoCategory(_ items: [TodoCategoryItem]) async
    func updateWebPageURLInput(_ input: String) async
    func addWebPage() async
    func deleteWebPage(_ page: WebPageItem) async
    func undoDeleteWebPage() async
    func finishDeleteWebPageToast(_ urlString: String) async
}

@MainActor
struct HomeViewModelTestAdapter: HomeStateDriving {
    private let viewModel: HomeViewModel

    var preferences: [TodoCategoryItem] { viewModel.state.preferences }
    var recentTodos: [RecentTodoItem] { viewModel.state.recentTodos }
    var webPages: [WebPageItem] { viewModel.state.webPages }
    var isNetworkConnected: Bool { viewModel.state.isNetworkConnected }
    var showContentPicker: Bool { viewModel.state.showContentPicker }
    var showWebPageInputNavigation: Bool { false }
    var showTodoEditor: Bool { viewModel.state.showTodoEditor }
    var showAlert: Bool { viewModel.state.showAlert }
    var alertType: HomeFeature.AlertType? { viewModel.state.alertType?.featureValue }
    var alertTitle: String { viewModel.state.alertTitle }
    var webPageURLInput: String { viewModel.state.webPageURLInput }

    init(
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase = FetchTodoCategoryPreferencesUseCaseSpy(),
        updatePreferencesUseCase: UpdateTodoCategoryPreferencesUseCase = UpdateTodoCategoryPreferencesUseCaseSpy(),
        addWebPageUseCase: AddWebPageUseCase = AddWebPageUseCaseSpy(),
        deleteWebPageUseCase: DeleteWebPageUseCase = DeleteWebPageUseCaseSpy(),
        undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase = UndoDeleteWebPageUseCaseSpy(),
        fetchTodosUseCase: FetchTodosUseCase = FetchTodosUseCaseSpy(),
        fetchWebPagesUseCase: FetchWebPagesUseCase = FetchWebPagesUseCaseSpy(webPages: []),
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase = ObserveNetworkConnectivityUseCaseSpy(),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase = HomeTrackAnalyticsEventUseCaseSpy()
    ) {
        viewModel = HomeViewModel(
            fetchPreferencesUseCase: fetchPreferencesUseCase,
            updatePreferencesUseCase: updatePreferencesUseCase,
            addWebPageUseCase: addWebPageUseCase,
            deleteWebPageUseCase: deleteWebPageUseCase,
            undoDeleteWebPageUseCase: undoDeleteWebPageUseCase,
            fetchTodosUseCase: fetchTodosUseCase,
            fetchWebPagesUseCase: fetchWebPagesUseCase,
            networkConnectivityUseCase: networkConnectivityUseCase,
            trackAnalyticsEventUseCase: trackAnalyticsEventUseCase
        )
    }

    func startObserving() async { }

    func fetchData() async {
        viewModel.send(.fetchData)
    }

    func openWebPageInput() async {
        viewModel.send(.setAlert(isPresented: true, type: .webPageInput))
    }

    func setPresentation(_ presentation: HomeFeature.Presentation, _ isPresented: Bool) async {
        viewModel.send(.setPresentation(presentation.viewModelValue, isPresented))
    }

    func setAlert(isPresented: Bool, type: HomeFeature.AlertType?) async {
        viewModel.send(.setAlert(isPresented: isPresented, type: type?.viewModelValue))
    }

    func tapTodoCategory(_ category: TodoCategory) async {
        viewModel.send(.tapTodoCategory(category))
    }

    func orderTodoCategory(_ items: [TodoCategoryItem]) async {
        viewModel.send(.orderTodoCategory(items))
    }

    func updateWebPageURLInput(_ input: String) async {
        viewModel.send(.updateWebPageURLInput(input))
    }

    func addWebPage() async {
        viewModel.send(.addWebPage)
    }

    func deleteWebPage(_ page: WebPageItem) async {
        viewModel.send(.deleteWebPage(page))
    }

    func undoDeleteWebPage() async {
        viewModel.send(.undoDeleteWebPage)
    }

    func finishDeleteWebPageToast(_ urlString: String) async {
        viewModel.send(.finishDeleteWebPageToast(urlString))
    }
}

@MainActor
struct HomeStoreTestAdapter: HomeStateDriving {
    private let store: TestStoreOf<HomeFeature>

    var preferences: [TodoCategoryItem] { store.state.preferences }
    var recentTodos: [RecentTodoItem] { store.state.recentTodos }
    var webPages: [WebPageItem] { store.state.webPages }
    var isNetworkConnected: Bool { store.state.isNetworkConnected }
    var showContentPicker: Bool { store.state.showContentPicker }
    var showWebPageInputNavigation: Bool {
        store.state.sheet?.contentPickerState?.webPageInput != nil
    }
    var showTodoEditor: Bool { store.state.showTodoEditor }
    var showAlert: Bool { store.state.alert != nil }
    var alertType: HomeFeature.AlertType? {
        guard let title = store.state.alert?.title else { return nil }
        if title == TextState(String(localized: "home_invalid_url_title")) {
            return .invalidURL
        }
        if title == TextState(String(localized: "common_error_title")) {
            return .error
        }
        return nil
    }
    var alertTitle: String {
        if let title = store.state.alert?.title {
            return String(state: title)
        }
        return ""
    }
    var webPageURLInput: String { store.state.webPageURLInput }

    init(
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase = FetchTodoCategoryPreferencesUseCaseSpy(),
        updatePreferencesUseCase: UpdateTodoCategoryPreferencesUseCase = UpdateTodoCategoryPreferencesUseCaseSpy(),
        addWebPageUseCase: AddWebPageUseCase = AddWebPageUseCaseSpy(),
        deleteWebPageUseCase: DeleteWebPageUseCase = DeleteWebPageUseCaseSpy(),
        undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase = UndoDeleteWebPageUseCaseSpy(),
        fetchTodosUseCase: FetchTodosUseCase = FetchTodosUseCaseSpy(),
        fetchWebPagesUseCase: FetchWebPagesUseCase = FetchWebPagesUseCaseSpy(webPages: []),
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase = ObserveNetworkConnectivityUseCaseSpy(),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase? = HomeTrackAnalyticsEventUseCaseSpy(),
        configureDependencies: ((inout DependencyValues) -> Void)? = nil
    ) {
        store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.fetchTodoCategoryPreferencesUseCase = fetchPreferencesUseCase
            $0.homeUpdateTodoCategoryPreferencesUseCase = updatePreferencesUseCase
            $0.homeAddWebPageUseCase = addWebPageUseCase
            $0.homeDeleteWebPageUseCase = deleteWebPageUseCase
            $0.homeUndoDeleteWebPageUseCase = undoDeleteWebPageUseCase
            $0.homeFetchTodosUseCase = fetchTodosUseCase
            $0.homeFetchWebPagesUseCase = fetchWebPagesUseCase
            $0.networkConnectivityUseCase = networkConnectivityUseCase
            $0.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
            $0.continuousClock = ContinuousClock()
            configureDependencies?(&$0)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func startObserving() async {
        await store.send(.startObserving)
        await drainReceivedActions()
    }

    func fetchData() async {
        await store.send(.fetchData)
        await drainReceivedActions()
    }

    func openWebPageInput() async {
        await store.send(.sheet(.presented(.contentPicker(.tapWebPageInput))))
        await drainReceivedActions()
    }

    func setPresentation(_ presentation: HomeFeature.Presentation, _ isPresented: Bool) async {
        await store.send(.setPresentation(presentation, isPresented))
    }

    func setAlert(isPresented: Bool, type: HomeFeature.AlertType?) async {
        await store.send(.setAlert(isPresented: isPresented, type: type))
        await drainReceivedActions()
    }

    func tapTodoCategory(_ category: TodoCategory) async {
        await store.send(.tapTodoCategory(category))
        await drainReceivedActions()
    }

    func orderTodoCategory(_ items: [TodoCategoryItem]) async {
        await store.send(.orderTodoCategory(items))
        await drainReceivedActions()
    }

    func updateWebPageURLInput(_ input: String) async {
        await store.send(.updateWebPageURLInput(input))
    }

    func addWebPage() async {
        await store.send(.addWebPage)
        await drainReceivedActions()
    }

    func deleteWebPage(_ page: WebPageItem) async {
        await store.send(.deleteWebPage(page))
        await drainReceivedActions()
    }

    func undoDeleteWebPage() async {
        await store.send(.undoDeleteWebPage)
        await drainReceivedActions()
    }

    func finishDeleteWebPageToast(_ urlString: String) async {
        await store.send(.finishDeleteWebPageToast(urlString))
    }

    private func drainReceivedActions() async {
        for _ in 0..<12 {
            await store.skipReceivedActions(strict: false)
        }
    }
}

final class HomeTrackAnalyticsEventUseCaseSpy: TrackAnalyticsEventUseCase {
    private(set) var events = [AnalyticsEvent]()

    func execute(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

func makeHomeTodo(
    id: String,
    category: TodoCategory = .system(.feature),
    number: Int = 1,
    title: String = "Todo",
    isPinned: Bool = false,
    tags: [String] = [],
    createdAt: Date = Date(timeIntervalSince1970: 0),
    updatedAt: Date = Date(timeIntervalSince1970: 10)
) -> Todo {
    Todo(
        id: id,
        isPinned: isPinned,
        isCompleted: false,
        isChecked: false,
        number: number,
        title: title,
        content: "content",
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: tags,
        category: category
    )
}

func makeHomeWebPage(
    title: String = "OpenAI",
    urlString: String = "https://openai.com"
) -> WebPage {
    let url = URL(string: urlString)!
    return WebPage(
        title: title,
        url: url,
        displayURL: url,
        imageURL: nil
    )
}

private extension HomeViewModel.AlertType {
    var featureValue: HomeFeature.AlertType {
        switch self {
        case .invalidURL:
            return .invalidURL
        case .error:
            return .error
        }
    }
}

private extension HomeFeature.AlertType {
    var viewModelValue: HomeViewModel.AlertType {
        switch self {
        case .invalidURL:
            return .invalidURL
        case .error:
            return .error
        }
    }
}

private extension HomeFeature.Presentation {
    var viewModelValue: HomeViewModel.Presentation {
        switch self {
        case .todoEditor:
            return .todoEditor
        case .contentPicker:
            return .contentPicker
        case .searchView:
            return .searchView
        }
    }
}
