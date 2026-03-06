//
//  MainView.swift
//  DevLog
//
//  Created by opfic on 5/8/25.
//

import SwiftUI

struct MainView: View {
    @Environment(\.diContainer) var container: DIContainer

    var body: some View {
        TabView {
            HomeView(viewModel: HomeViewModel(
                addWebPageUseCase: container.resolve(AddWebPageUseCase.self),
                deleteWebPageUseCase: container.resolve(DeleteWebPageUseCase.self),
                upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                fetchWebPagesUseCase: container.resolve(FetchWebPagesUseCase.self)
            ))
            .tabItem {
                Image(systemName: "house.fill")
                Text("홈")
            }
            TodayView(viewModel: TodayViewModel(
                fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                fetchTodoByIDUseCase: container.resolve(FetchTodoByIDUseCase.self),
                upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self)
            ))
            .tabItem {
                Image(systemName: "sun.max.fill")
                Text("오늘")
            }
            PushNotificationListView(viewModel: PushNotificationListViewModel(
                fetchUseCase: container.resolve(FetchPushNotificationsUseCase.self),
                deleteUseCase: container.resolve(DeletePushNotificationUseCase.self),
                toggleReadUseCase: container.resolve(TogglePushNotificationReadUseCase.self),
                fetchQueryUseCase: container.resolve(FetchPushNotificationQueryUseCase.self),
                updateQueryUseCase: container.resolve(UpdatePushNotificationQueryUseCase.self)
            ))
            .tabItem {
                Image(systemName: "bell.fill")
                Text("알림")
            }
            ProfileView(viewModel: ProfileViewModel(
                fetchUserDataUseCase: container.resolve(FetchUserDataUseCase.self),
                fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                upsertStatusMessageUseCase: container.resolve(UpsertStatusMessageUseCase.self),
                fetchHeatmapActivityTypesUseCase: container.resolve(FetchProfileHeatmapActivityTypesUseCase.self),
                updateHeatmapActivityTypesUseCase: container.resolve(UpdateProfileHeatmapActivityTypesUseCase.self)
            ))
            .tabItem {
                Image(systemName: "person.crop.circle.fill")
                Text("프로필")
            }
        }
    }
}
