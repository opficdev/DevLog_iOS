//
//  HomeViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/10/26.
//

import Combine
import Foundation
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class HomeViewCoordinator {
    let viewModel: HomeViewModel
    let router = NavigationRouter<HomeRoute>()
    private let diContainer: DIContainer
    @ObservationIgnored
    private var cancellable: AnyCancellable?

    init(container: DIContainer) {
        self.diContainer = container
        self.viewModel = HomeViewModel(
            fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
            updatePreferencesUseCase: container.resolve(UpdateTodoCategoryPreferencesUseCase.self),
            addWebPageUseCase: container.resolve(AddWebPageUseCase.self),
            deleteWebPageUseCase: container.resolve(DeleteWebPageUseCase.self),
            undoDeleteWebPageUseCase: container.resolve(UndoDeleteWebPageUseCase.self),
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            fetchWebPagesUseCase: container.resolve(FetchWebPagesUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self)
        )
    }

    func fetchData() {
        viewModel.send(.fetchData)
    }

    func bindWindowEvent(_ windowEvent: TodoEditorWindowEvent) {
        guard cancellable == nil else { return }

        cancellable = windowEvent.submits
            .sink { [weak self] submit in
                guard submit.value.matchesCreate(source: .home) else { return }
                self?.viewModel.send(.fetchData)
            }
    }

    func makeTodoManageViewModel() -> TodoManageViewModel {
        TodoManageViewModel(viewModel.state.preferences)
    }

    func makeTodoEditorViewModel(category: TodoCategory) -> TodoEditorViewModel {
        TodoEditorViewModel(
            category: category,
            fetchPreferencesUseCase: diContainer.resolve(FetchTodoCategoryPreferencesUseCase.self),
            fetchReferenceItemsUseCase: diContainer.resolve(FetchReferenceItemsUseCase.self),
            upsertTodoUseCase: diContainer.resolve(UpsertTodoUseCase.self),
            trackAnalyticsEventUseCase: diContainer.resolve(TrackAnalyticsEventUseCase.self),
            onUpsertSuccess: { [weak self] _ in
                self?.viewModel.send(.setPresentation(.todoEditor, false))
                self?.viewModel.send(.fetchData)
            }
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            fetchWebPagesUseCase: diContainer.resolve(FetchWebPagesUseCase.self),
            fetchTodosUseCase: diContainer.resolve(FetchTodosUseCase.self),
            fetchRecentSearchQueriesUseCase: diContainer.resolve(FetchRecentSearchQueriesUseCase.self),
            updateRecentSearchQueriesUseCase: diContainer.resolve(UpdateRecentSearchQueriesUseCase.self)
        )
    }
}
