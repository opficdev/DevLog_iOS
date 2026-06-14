//
//  TodoWindowCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/31/26.
//

import Combine
import Foundation
import ComposableArchitecture
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class TodoWindowCoordinator {
    private let container: DIContainer
    @ObservationIgnored
    private var listStore: StoreOf<TodoListFeature>?
    @ObservationIgnored
    private var detailStore: StoreOf<TodoDetailFeature>?
    @ObservationIgnored
    private var cancellable: AnyCancellable?

    init(container: DIContainer) {
        self.container = container
    }

    func bindWindowEvent(_ windowEvent: TodoEditorWindowEvent) {
        guard cancellable == nil else { return }

        cancellable = windowEvent.submits
            .sink { [weak self] submit in
                self?.handleTodoEditorSubmit(submit)
            }
    }

    func makeListStore(category: TodoCategory) -> StoreOf<TodoListFeature> {
        if let listStore,
           listStore.category == category {
            return listStore
        }

        let listStore = Store(initialState: TodoListFeature.State(category: category)) {
            TodoListFeature()
        } withDependencies: {
            $0.todoListFetchTodosUseCase = self.container.resolve(FetchTodosUseCase.self)
            $0.fetchTodoByIdUseCase = self.container.resolve(FetchTodoByIdUseCase.self)
            $0.upsertTodoUseCase = self.container.resolve(UpsertTodoUseCase.self)
            $0.todoListDeleteTodoUseCase = self.container.resolve(DeleteTodoUseCase.self)
            $0.todoListUndoDeleteTodoUseCase = self.container.resolve(UndoDeleteTodoUseCase.self)
            $0.trackAnalyticsEventUseCase = self.container.resolve(TrackAnalyticsEventUseCase.self)
        }
        self.listStore = listStore
        return listStore
    }

    func makeDetailStore(
        todoId: String,
        showEditButton: Bool = true
    ) -> StoreOf<TodoDetailFeature> {
        if let detailStore,
           detailStore.todoId == todoId,
           detailStore.showEditButton == showEditButton {
            return detailStore
        }
        let detailStore = Store(
            initialState: TodoDetailFeature.State(
                todoId: todoId,
                showEditButton: showEditButton
            )
        ) {
            TodoDetailFeature()
        } withDependencies: {
            $0.fetchTodoByIdUseCase = self.container.resolve(FetchTodoByIdUseCase.self)
            $0.fetchReferenceItemsUseCase = self.container.resolve(FetchReferenceItemsUseCase.self)
        }
        self.detailStore = detailStore
        return detailStore
    }

    private func handleTodoEditorSubmit(_ submit: TodoEditorWindowSubmit) {
        switch submit {
        case .create(let value):
            if let listStore,
               value.matchesCreate(category: listStore.category, source: .list) {
                listStore.send(.view(.refresh))
            }
        case .update(let value, let todo):
            if let detailStore,
               value.matchesEdit(todoId: detailStore.todoId) {
                detailStore.send(.setTodo(todo))
            }
        }
    }
}
