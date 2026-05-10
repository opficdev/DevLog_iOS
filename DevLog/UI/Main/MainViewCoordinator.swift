//
//  MainViewCoordinator.swift
//  DevLog
//
//  Created by opfic on 5/9/26.
//

import Foundation

@MainActor
@Observable
final class MainViewCoordinator {
    let mainViewModel: MainViewModel
    let pushNotificationListViewModel: PushNotificationListViewModel
    let profileViewModel: ProfileViewModel
    var todoIdToPresent: TodoIdItem?

    init(container: DIContainer) {
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
}
