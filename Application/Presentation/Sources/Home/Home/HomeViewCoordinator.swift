//
//  HomeViewCoordinator.swift
//  Presentation
//
//  Created by opfic on 5/10/26.
//

import Combine
import ComposableArchitecture
import Foundation
import Core
import Domain

@MainActor
@Observable
final class HomeViewCoordinator {
    let store: StoreOf<HomeFeature>
    let router = NavigationRouter<HomeRoute>()
    private let container: DIContainer
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private var isTodoMutationEventBound = false
    @ObservationIgnored
    private var isWindowEventBound = false

    init(container: DIContainer) {
        self.container = container
        self.store = Store(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.fetchTodoCategoryPreferencesUseCase = container.resolve(FetchTodoCategoryPreferencesUseCase.self)
            $0.homeUpdateTodoCategoryPreferencesUseCase = container.resolve(
                UpdateTodoCategoryPreferencesUseCase.self
            )
            $0.homeAddWebPageUseCase = container.resolve(AddWebPageUseCase.self)
            $0.homeDeleteWebPageUseCase = container.resolve(DeleteWebPageUseCase.self)
            $0.homeUndoDeleteWebPageUseCase = container.resolve(UndoDeleteWebPageUseCase.self)
            $0.homeFetchTodosUseCase = container.resolve(FetchTodosUseCase.self)
            $0.homeFetchWebPagesUseCase = container.resolve(FetchWebPagesUseCase.self)
            $0.networkConnectivityUseCase = container.resolve(ObserveNetworkConnectivityUseCase.self)
            $0.fetchReferenceItemsUseCase = container.resolve(FetchReferenceItemsUseCase.self)
            $0.upsertTodoUseCase = container.resolve(UpsertTodoUseCase.self)
            $0.trackAnalyticsEventUseCase = container.resolve(TrackAnalyticsEventUseCase.self)
        }
        self.store.send(.view(.startObserving))
    }

    func fetchData() {
        store.send(.view(.fetchData))
    }

    func refreshRecentTodos() {
        store.send(.view(.refreshRecentTodos))
    }

    func bindTodoMutationEvent() {
        guard isTodoMutationEventBound == false else { return }
        isTodoMutationEventBound = true

        let bus = container.resolve(TodoMutationEventBus.self)
        bus.observe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .updated, .deleted, .restored:
                    self.refreshRecentTodos()
                }
            }
            .store(in: &cancellables)
    }

    func bindWindowEvent(_ windowEvent: TodoEditorWindowEvent) {
        guard isWindowEventBound == false else { return }
        isWindowEventBound = true

        windowEvent.submits
            .sink { [weak self] submit in
                guard case .create(let value) = submit,
                      value.matchesCreate(source: .home) else { return }
                self?.store.send(.view(.fetchData))
            }
            .store(in: &cancellables)
    }

    func makeSearchStore() -> StoreOf<SearchFeature> {
        Store(
            initialState: SearchFeature.State(
                recentQueries: container.resolve(FetchRecentSearchQueriesUseCase.self).execute()
            )
        ) {
            SearchFeature()
        } withDependencies: {
            $0.searchFetchWebPagesUseCase = self.container.resolve(FetchWebPagesUseCase.self)
            $0.searchFetchTodosUseCase = self.container.resolve(FetchTodosUseCase.self)
            $0.searchUpdateRecentQueriesUseCase = self.container.resolve(UpdateRecentSearchQueriesUseCase.self)
        }
    }
}
