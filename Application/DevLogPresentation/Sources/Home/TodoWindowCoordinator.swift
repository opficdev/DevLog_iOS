//
//  TodoWindowCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/31/26.
//

import Foundation
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class TodoWindowCoordinator {
    private let diContainer: DIContainer
    @ObservationIgnored
    private var listViewModel: TodoListViewModel?
    @ObservationIgnored
    private var detailViewModel: TodoDetailViewModel?

    init(container: DIContainer) {
        self.diContainer = container
    }

    func makeListViewModel(category: TodoCategory) -> TodoListViewModel {
        if let listViewModel,
           listViewModel.category == category {
            return listViewModel
        }

        let listViewModel = TodoListViewModel(
            fetchTodosUseCase: diContainer.resolve(FetchTodosUseCase.self),
            fetchTodoByIdUseCase: diContainer.resolve(FetchTodoByIdUseCase.self),
            upsertTodoUseCase: diContainer.resolve(UpsertTodoUseCase.self),
            deleteTodoUseCase: diContainer.resolve(DeleteTodoUseCase.self),
            undoDeleteTodoUseCase: diContainer.resolve(UndoDeleteTodoUseCase.self),
            trackAnalyticsEventUseCase: diContainer.resolve(TrackAnalyticsEventUseCase.self),
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
            fetchTodoUseCase: diContainer.resolve(FetchTodoByIdUseCase.self),
            fetchReferenceItemsUseCase: diContainer.resolve(FetchReferenceItemsUseCase.self),
            upsertUseCase: diContainer.resolve(UpsertTodoUseCase.self),
            todoId: todoId,
            showEditButton: showEditButton
        )
        self.detailViewModel = detailViewModel
        return detailViewModel
    }
}
