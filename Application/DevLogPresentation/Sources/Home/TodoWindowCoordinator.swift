//
//  TodoWindowCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/31/26.
//

import Combine
import Foundation
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class TodoWindowCoordinator {
    private let container: DIContainer
    @ObservationIgnored
    private var listViewModel: TodoListViewModel?
    @ObservationIgnored
    private var detailViewModel: TodoDetailViewModel?
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

    func makeDetailViewModel(
        todoId: String,
        showEditButton: Bool = true
    ) -> TodoDetailViewModel {
        if let detailViewModel,
           detailViewModel.todoId == todoId,
           detailViewModel.showEditButton == showEditButton {
            return detailViewModel
        }

        let detailViewModel = TodoDetailViewModel(
            fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
            todoId: todoId,
            showEditButton: showEditButton
        )
        self.detailViewModel = detailViewModel
        return detailViewModel
    }

    private func handleTodoEditorSubmit(_ submit: TodoEditorWindowSubmit) {
        switch submit {
        case .create(let value):
            if let listViewModel,
               value.matchesCreate(category: listViewModel.category, source: .list) {
                listViewModel.send(.refresh)
            }
        case .update(let value, let todo):
            if let detailViewModel,
               value.matchesEdit(todoId: detailViewModel.todoId) {
                detailViewModel.send(.setTodo(todo))
            }
        }
    }
}
