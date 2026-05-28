//
//  MainViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/9/26.
//

import Foundation
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class MainViewCoordinator {
    let mainViewModel: MainViewModel
    private let diContainer: DIContainer
    @ObservationIgnored
    private var todoListViewModel: TodoListViewModel?
    @ObservationIgnored
    private var todoDetailViewModel: TodoDetailViewModel?

    init(container: DIContainer) {
        self.diContainer = container
        self.mainViewModel = MainViewModel(
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
            unreadPushCountUseCase: container.resolve(ObserveUnreadPushCountUseCase.self)
        )
    }

    func todoListViewModel(category: TodoCategory) -> TodoListViewModel {
        if let todoListViewModel,
           todoListViewModel.category == category {
            return todoListViewModel
        }

        let todoListViewModel = TodoListViewModel(
            fetchTodosUseCase: diContainer.resolve(FetchTodosUseCase.self),
            fetchTodoByIdUseCase: diContainer.resolve(FetchTodoByIdUseCase.self),
            upsertTodoUseCase: diContainer.resolve(UpsertTodoUseCase.self),
            deleteTodoUseCase: diContainer.resolve(DeleteTodoUseCase.self),
            undoDeleteTodoUseCase: diContainer.resolve(UndoDeleteTodoUseCase.self),
            trackAnalyticsEventUseCase: diContainer.resolve(TrackAnalyticsEventUseCase.self),
            category: category
        )
        self.todoListViewModel = todoListViewModel
        return todoListViewModel
    }

    func todoDetailViewModel(
        todoId: String,
        showEditButton: Bool = true
    ) -> TodoDetailViewModel {
        if let todoDetailViewModel,
           todoDetailViewModel.todoId == todoId,
           todoDetailViewModel.showEditButton == showEditButton {
            return todoDetailViewModel
        }

        let todoDetailViewModel = TodoDetailViewModel(
            fetchTodoUseCase: diContainer.resolve(FetchTodoByIdUseCase.self),
            fetchReferenceItemsUseCase: diContainer.resolve(FetchReferenceItemsUseCase.self),
            upsertUseCase: diContainer.resolve(UpsertTodoUseCase.self),
            todoId: todoId,
            showEditButton: showEditButton
        )
        self.todoDetailViewModel = todoDetailViewModel
        return todoDetailViewModel
    }
}
