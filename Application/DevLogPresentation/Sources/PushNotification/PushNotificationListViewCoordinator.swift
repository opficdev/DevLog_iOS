//
//  PushNotificationListViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/29/26.
//

import Foundation
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class PushNotificationListViewCoordinator {
    let viewModel: PushNotificationListViewModel
    var todoIdToPresent: TodoIdItem?
    private let container: DIContainer
    @ObservationIgnored
    private var todoDetailViewModel: TodoDetailViewModel?

    init(container: DIContainer) {
        self.container = container
        self.viewModel = PushNotificationListViewModel(
            fetchUseCase: container.resolve(FetchPushNotificationsUseCase.self),
            deleteUseCase: container.resolve(DeletePushNotificationUseCase.self),
            undoDeleteUseCase: container.resolve(UndoDeletePushNotificationUseCase.self),
            toggleReadUseCase: container.resolve(TogglePushNotificationReadUseCase.self),
            fetchQueryUseCase: container.resolve(FetchPushNotificationQueryUseCase.self),
            updateQueryUseCase: container.resolve(UpdatePushNotificationQueryUseCase.self)
        )
    }

    func fetchData() {
        viewModel.send(.fetchNotifications)
    }

    func makeTodoDetailViewModel(todoId: String) -> TodoDetailViewModel {
        if let todoDetailViewModel,
           todoDetailViewModel.todoId == todoId,
           !todoDetailViewModel.showEditButton {
            return todoDetailViewModel
        }

        let todoDetailViewModel = TodoDetailViewModel(
            fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
            todoId: todoId,
            showEditButton: false
        )
        self.todoDetailViewModel = todoDetailViewModel
        return todoDetailViewModel
    }
}
