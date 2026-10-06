//
//  HomeDependencyPreparation.swift
//  HomeTab
//
//  Created by opfic on 9/7/26.
//

import Domain
import PresentationShared

public enum HomeDependencyPreparation {
    public static func prepareDevelopmentGoal(
        _ dependencies: inout DependencyValues,
        fetchGoalsUseCase: FetchDevelopmentGoalsUseCase,
        recentRecordUseCase: FetchRecentDevelopmentRecordUseCase,
        fetchTodosUseCase: FetchTodosUseCase
    ) {
        dependencies.homeFetchDevelopmentGoalsUseCase = fetchGoalsUseCase
        dependencies.homeFetchRecentDevelopmentRecordUseCase = recentRecordUseCase
        dependencies.homeFetchTodosUseCase = fetchTodosUseCase
    }

    public static func prepareTodoCategory(
        _ dependencies: inout DependencyValues,
        updateTodoCategoryPreferencesUseCase: UpdateTodoCategoryPreferencesUseCase
    ) {
        dependencies.homeUpdateTodoCategoryPreferencesUseCase = updateTodoCategoryPreferencesUseCase
    }

    public static func prepareTodo(
        _ dependencies: inout DependencyValues,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    ) {
        dependencies.homeNetworkConnectivityUseCase = networkConnectivityUseCase
    }

    public static func prepareTodoListQuery(
        _ dependencies: inout DependencyValues,
        fetchTodosUseCase: FetchTodosUseCase,
        fetchTodoByIdUseCase: FetchTodoByIdUseCase,
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase,
        fetchTodoCategoryPreferencesUseCase: FetchTodoCategoryPreferencesUseCase
    ) {
        dependencies.todoListFetchTodosUseCase = fetchTodosUseCase
        dependencies.fetchTodoByIdUseCase = fetchTodoByIdUseCase
        dependencies.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
        dependencies.fetchTodoCategoryPreferencesUseCase = fetchTodoCategoryPreferencesUseCase
    }

    public static func prepareTodoListMutation(
        _ dependencies: inout DependencyValues,
        upsertTodoUseCase: UpsertTodoUseCase,
        deleteTodoUseCase: DeleteTodoUseCase,
        undoDeleteTodoUseCase: UndoDeleteTodoUseCase,
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase
    ) {
        dependencies.upsertTodoUseCase = upsertTodoUseCase
        dependencies.todoListDeleteTodoUseCase = deleteTodoUseCase
        dependencies.todoListUndoDeleteTodoUseCase = undoDeleteTodoUseCase
        dependencies.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
    }

    public static func prepareSearch(
        _ dependencies: inout DependencyValues,
        fetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        updateRecentSearchQueriesUseCase: UpdateRecentSearchQueriesUseCase
    ) {
        dependencies.homeFetchRecentSearchQueriesUseCase = fetchRecentSearchQueriesUseCase
        dependencies.searchFetchTodosUseCase = fetchTodosUseCase
        dependencies.searchUpdateRecentQueriesUseCase = updateRecentSearchQueriesUseCase
    }
}

extension DependencyValues {
    var homeFetchTodosUseCase: FetchTodosUseCase {
        get { self[FetchTodosUseCaseKey.self] }
        set { self[FetchTodosUseCaseKey.self] = newValue }
    }

    var homeFetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase {
        get { self[FetchRecentSearchQueriesUseCaseKey.self] }
        set { self[FetchRecentSearchQueriesUseCaseKey.self] = newValue }
    }
}

private enum FetchTodosUseCaseKey: DependencyKey {
    static var liveValue: FetchTodosUseCase {
        preconditionFailure("FetchTodosUseCase must be provided.")
    }
}

private enum FetchRecentSearchQueriesUseCaseKey: DependencyKey {
    static var liveValue: FetchRecentSearchQueriesUseCase {
        preconditionFailure("FetchRecentSearchQueriesUseCase must be provided.")
    }
}
