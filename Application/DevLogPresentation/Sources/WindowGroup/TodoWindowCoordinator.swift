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
    private var listViewModel: TodoListViewModel?
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

    func makeListViewModel(category: TodoCategory) -> TodoListViewModel {
        if let listViewModel,
           listViewModel.category == category {
            return listViewModel
        }

        let listViewModel = TodoListViewModel(
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            deleteTodoUseCase: container.resolve(DeleteTodoUseCase.self),
            undoDeleteTodoUseCase: container.resolve(UndoDeleteTodoUseCase.self),
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
            category: category
        )
        self.listViewModel = listViewModel
        return listViewModel
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
            if let listViewModel,
               value.matchesCreate(category: listViewModel.category, source: .list) {
                listViewModel.send(.refresh)
            }
        case .update(let value, let todo):
            if let detailStore,
               value.matchesEdit(todoId: detailStore.todoId) {
                detailStore.send(.setTodo(todo))
            }
        }
    }
}
