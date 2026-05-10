//
//  HomeViewCoordinator.swift
//  DevLog
//
//  Created by opfic on 5/10/26.
//

import Foundation

@MainActor
@Observable
final class HomeViewCoordinator {
    let viewModel: HomeViewModel
    let router = NavigationRouter<HomeRoute>()
    private let fetchTodoCategoryPreferencesUseCase: FetchTodoCategoryPreferencesUseCase
    private let fetchReferenceItemsUseCase: FetchReferenceItemsUseCase
    private let fetchWebPagesUseCase: FetchWebPagesUseCase
    private let fetchTodosUseCase: FetchTodosUseCase
    private let fetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase
    private let updateRecentSearchQueriesUseCase: UpdateRecentSearchQueriesUseCase

    init(container: DIContainer) {
        let fetchTodoCategoryPreferencesUseCase = container.resolve(FetchTodoCategoryPreferencesUseCase.self)
        let fetchWebPagesUseCase = container.resolve(FetchWebPagesUseCase.self)
        let fetchTodosUseCase = container.resolve(FetchTodosUseCase.self)

        self.fetchTodoCategoryPreferencesUseCase = fetchTodoCategoryPreferencesUseCase
        self.fetchReferenceItemsUseCase = container.resolve(FetchReferenceItemsUseCase.self)
        self.fetchWebPagesUseCase = fetchWebPagesUseCase
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchRecentSearchQueriesUseCase = container.resolve(FetchRecentSearchQueriesUseCase.self)
        self.updateRecentSearchQueriesUseCase = container.resolve(UpdateRecentSearchQueriesUseCase.self)
        self.viewModel = HomeViewModel(
            fetchPreferencesUseCase: fetchTodoCategoryPreferencesUseCase,
            updatePreferencesUseCase: container.resolve(UpdateTodoCategoryPreferencesUseCase.self),
            addWebPageUseCase: container.resolve(AddWebPageUseCase.self),
            deleteWebPageUseCase: container.resolve(DeleteWebPageUseCase.self),
            undoDeleteWebPageUseCase: container.resolve(UndoDeleteWebPageUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            fetchTodosUseCase: fetchTodosUseCase,
            fetchWebPagesUseCase: fetchWebPagesUseCase,
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self)
        )
    }

    func makeTodoManageViewModel() -> TodoManageViewModel {
        TodoManageViewModel(viewModel.state.preferences)
    }

    func makeTodoEditorViewModel(category: TodoCategory) -> TodoEditorViewModel {
        TodoEditorViewModel(
            category: category,
            fetchPreferencesUseCase: fetchTodoCategoryPreferencesUseCase,
            fetchReferenceItemsUseCase: fetchReferenceItemsUseCase
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            fetchWebPagesUseCase: fetchWebPagesUseCase,
            fetchTodosUseCase: fetchTodosUseCase,
            fetchRecentSearchQueriesUseCase: fetchRecentSearchQueriesUseCase,
            updateRecentSearchQueriesUseCase: updateRecentSearchQueriesUseCase
        )
    }
}
