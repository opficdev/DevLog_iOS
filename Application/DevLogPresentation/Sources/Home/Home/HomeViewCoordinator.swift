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
    private let container: DIContainer
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private var isTodoMutationEventBound = false
    @ObservationIgnored
    private var isWindowEventBound = false

    init(container: DIContainer) {
        self.container = container
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

    func refreshRecentTodos() {
        viewModel.send(.refreshRecentTodos)
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
                self?.viewModel.send(.fetchData)
            }
            .store(in: &cancellables)
    }

    func makeTodoEditorViewModel(category: TodoCategory) -> TodoEditorViewModel {
        TodoEditorViewModel(
            category: category,
            fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
            onCreateSuccess: { [weak self] in
                self?.viewModel.send(.setPresentation(.todoEditor, false))
                self?.viewModel.send(.fetchData)
            }
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            fetchWebPagesUseCase: container.resolve(FetchWebPagesUseCase.self),
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            fetchRecentSearchQueriesUseCase: container.resolve(FetchRecentSearchQueriesUseCase.self),
            updateRecentSearchQueriesUseCase: container.resolve(UpdateRecentSearchQueriesUseCase.self)
        )
    }
}
