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
    let store: StoreOf<PushNotificationListFeature>
    private let container: DIContainer
    @ObservationIgnored
    private var todoDetailStore: StoreOf<TodoDetailFeature>?

    init(container: DIContainer) {
        self.container = container
        let fetchQueryUseCase = container.resolve(FetchPushNotificationQueryUseCase.self)

        self.store = Store(
            initialState: PushNotificationListFeature.State(
                query: fetchQueryUseCase.execute()
            )
        ) {
            PushNotificationListFeature()
        } withDependencies: {
            $0.fetchPushNotificationsUseCase = container.resolve(FetchPushNotificationsUseCase.self)
            $0.deletePushNotificationUseCase = container.resolve(DeletePushNotificationUseCase.self)
            $0.undoDeletePushNotificationUseCase = container.resolve(UndoDeletePushNotificationUseCase.self)
            $0.togglePushNotificationReadUseCase = container.resolve(TogglePushNotificationReadUseCase.self)
            $0.updatePushNotificationQueryUseCase = container.resolve(UpdatePushNotificationQueryUseCase.self)
        }
    }

    func fetchData() {
        store.send(.fetchNotifications)
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
