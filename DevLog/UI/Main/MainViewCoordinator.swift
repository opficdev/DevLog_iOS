//
//  MainViewCoordinator.swift
//  DevLog
//
//  Created by opfic on 5/9/26.
//

import Foundation
import DevLogDomain
import DevLogPresentation

@MainActor
@Observable
final class MainViewCoordinator {
    let mainViewModel: MainViewModel
    let pushNotificationListViewModel: PushNotificationListViewModel
    let profileViewModel: ProfileViewModel
    var todoIdToPresent: TodoIdItem?
    private let diContainer: DIContainer
    @ObservationIgnored
    private var todoListViewModel: TodoListViewModel?
    @ObservationIgnored
    private var todoDetailViewModel: TodoDetailViewModel?

    init(container: DIContainer) {
        self.diContainer = container
        self.mainViewModel = MainViewModel(
            unreadPushCountUseCase: container.resolve(ObserveUnreadPushCountUseCase.self)
        )
        self.pushNotificationListViewModel = PushNotificationListViewModel(
            fetchUseCase: container.resolve(FetchPushNotificationsUseCase.self),
            deleteUseCase: container.resolve(DeletePushNotificationUseCase.self),
            undoDeleteUseCase: container.resolve(UndoDeletePushNotificationUseCase.self),
            toggleReadUseCase: container.resolve(TogglePushNotificationReadUseCase.self),
            fetchQueryUseCase: container.resolve(FetchPushNotificationQueryUseCase.self),
            updateQueryUseCase: container.resolve(UpdatePushNotificationQueryUseCase.self)
        )
        self.profileViewModel = ProfileViewModel(
            fetchUserDataUseCase: container.resolve(FetchUserDataUseCase.self),
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            upsertStatusMessageUseCase: container.resolve(UpsertStatusMessageUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
            fetchHeatmapActivityTypesUseCase: container.resolve(FetchHeatmapActivityTypesUseCase.self),
            updateHeatmapActivityTypesUseCase: container.resolve(UpdateHeatmapActivityTypesUseCase.self)
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
