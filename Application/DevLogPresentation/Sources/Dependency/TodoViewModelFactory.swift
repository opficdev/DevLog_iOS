//
//  TodoViewModelFactory.swift
//  DevLogPresentation
//
//  Created by opfic on 6/2/26.
//

import DevLogCore
import DevLogDomain

@MainActor
public struct TodoViewModelFactory {
    private let container: DIContainer

    public init(container: DIContainer) {
        self.container = container
    }

    public func makeDetailViewModel(
        todoId: String,
        showEditButton: Bool = true
    ) -> TodoDetailViewModel {
        TodoDetailViewModel(
            fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
            todoId: todoId,
            showEditButton: showEditButton
        )
    }

    public func makeEditorViewModel(
        category: TodoCategory,
        onUpsertSuccess: ((Todo) -> Void)? = nil
    ) -> TodoEditorViewModel {
        TodoEditorViewModel(
            category: category,
            fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
            onUpsertSuccess: onUpsertSuccess
        )
    }

    public func makeEditorViewModel(
        todo: Todo,
        onUpsertSuccess: ((Todo) -> Void)? = nil
    ) -> TodoEditorViewModel {
        TodoEditorViewModel(
            todo: todo,
            fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            onUpsertSuccess: onUpsertSuccess
        )
    }
}
