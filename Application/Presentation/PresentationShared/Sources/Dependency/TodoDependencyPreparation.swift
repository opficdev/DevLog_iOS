//
//  TodoDependencyPreparation.swift
//  PresentationShared
//
//  Created by opfic on 9/7/26.
//

import Domain

public enum TodoDependencyPreparation {
    public static func prepareDetail(
        _ dependencies: inout DependencyValues,
        fetchTodoByIdUseCase: FetchTodoByIdUseCase,
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase
    ) {
        dependencies.fetchTodoByIdUseCase = fetchTodoByIdUseCase
        dependencies.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
    }

    public static func prepareEditor(
        _ dependencies: inout DependencyValues,
        fetchTodoCategoryPreferencesUseCase: FetchTodoCategoryPreferencesUseCase,
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase,
        upsertTodoUseCase: UpsertTodoUseCase
    ) {
        dependencies.fetchTodoCategoryPreferencesUseCase = fetchTodoCategoryPreferencesUseCase
        dependencies.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
        dependencies.upsertTodoUseCase = upsertTodoUseCase
    }

}
