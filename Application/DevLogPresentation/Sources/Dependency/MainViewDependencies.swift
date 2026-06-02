//
//  MainViewDependencies.swift
//  DevLogPresentation
//
//  Created by opfic on 6/2/26.
//

import DevLogCore

@MainActor
public struct MainViewDependencies {
    public let coordinator: MainViewCoordinator
    public let todoWindowCoordinator: TodoWindowCoordinator
    public let homeViewCoordinator: HomeViewCoordinator
    public let todayViewCoordinator: TodayViewCoordinator
    public let pushNotificationListViewCoordinator: PushNotificationListViewCoordinator
    public let profileViewCoordinator: ProfileViewCoordinator
    public let todoViewModelFactory: TodoViewModelFactory

    public init(container: DIContainer) {
        self.coordinator = MainViewCoordinator(container: container)
        self.todoWindowCoordinator = TodoWindowCoordinator(container: container)
        self.homeViewCoordinator = HomeViewCoordinator(container: container)
        self.todayViewCoordinator = TodayViewCoordinator(container: container)
        self.pushNotificationListViewCoordinator = PushNotificationListViewCoordinator(container: container)
        self.profileViewCoordinator = ProfileViewCoordinator(container: container)
        self.todoViewModelFactory = TodoViewModelFactory(container: container)
    }
}
