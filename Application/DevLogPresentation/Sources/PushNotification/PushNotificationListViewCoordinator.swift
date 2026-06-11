//
//  PushNotificationListViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/29/26.
//

import Foundation
import ComposableArchitecture
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class PushNotificationListViewCoordinator {
    let viewModel: PushNotificationListViewModel
    var todoIdToPresent: TodoIdItem?
    private let container: DIContainer
    @ObservationIgnored
    private var todoDetailStore: StoreOf<TodoDetailFeature>?

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

    func makeTodoDetailStore(todoId: String) -> StoreOf<TodoDetailFeature> {
        if let todoDetailStore,
           todoDetailStore.todoId == todoId,
           !todoDetailStore.showEditButton {
            return todoDetailStore
        }

        let fetchTodoUseCase = container.resolve(FetchTodoByIdUseCase.self)
        let fetchReferenceItemsUseCase = container.resolve(FetchReferenceItemsUseCase.self)
        let todoDetailStore = Store(
            initialState: TodoDetailFeature.State(
                todoId: todoId,
                showEditButton: false
            )
        ) {
            TodoDetailFeature()
        } withDependencies: {
            $0.fetchTodoByIdUseCase = fetchTodoUseCase
            $0.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
        }
        self.todoDetailStore = todoDetailStore
        return todoDetailStore
    }
}
