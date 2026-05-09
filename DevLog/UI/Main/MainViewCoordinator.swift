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
    let homeViewModel: HomeViewModel
    let todayViewModel: TodayViewModel
    let pushNotificationListViewModel: PushNotificationListViewModel
    let profileViewModel: ProfileViewModel
    let homeNavigationRouter = NavigationRouter<HomeRoute>()
    let todayNavigationRouter = NavigationRouter<TodayRoute>()
    var todoIdToPresent: TodoIdItem?

    init(container: DIContainer) {
        self.mainViewModel = MainViewModel(
            unreadPushCountUseCase: container.resolve(ObserveUnreadPushCountUseCase.self)
        )
        self.homeViewModel = HomeViewModel(
            fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
            updatePreferencesUseCase: container.resolve(UpdateTodoCategoryPreferencesUseCase.self),
            addWebPageUseCase: container.resolve(AddWebPageUseCase.self),
            deleteWebPageUseCase: container.resolve(DeleteWebPageUseCase.self),
            undoDeleteWebPageUseCase: container.resolve(UndoDeleteWebPageUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            fetchWebPagesUseCase: container.resolve(FetchWebPagesUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self)
        )
        self.todayViewModel = TodayViewModel(
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            fetchTodayDisplayOptionsUseCase: container.resolve(FetchTodayDisplayOptionsUseCase.self),
            updateTodayDisplayOptionsUseCase: container.resolve(UpdateTodayDisplayOptionsUseCase.self)
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
