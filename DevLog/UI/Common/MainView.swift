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
                upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                fetchPinnedTodosUseCase: container.resolve(FetchPinnedTodosUseCase.self)
            ))
            .tabItem {
                Image(systemName: "house.fill")
                Text("홈")
            }
            PushNotificationView(viewModel: PushNotificationViewModel(
                fetchUseCase: container.resolve(FetchPushNotificationsUseCase.self),
                deleteUseCase: container.resolve(DeletePushNotificationUseCase.self)
            ))
            .tabItem {
                Image(systemName: "bell.fill")
                Text("알림")
            }
            SearchView(viewModel: SearchViewModel(
                fetchWebPagesUseCase: container.resolve(FetchWebPagesUseCase.self),
                addWebPageUseCase: container.resolve(AddWebPageUseCase.self),
                deleteWebPageUseCase: container.resolve(DeleteWebPageUseCase.self)
            ))
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("검색")
            }
            ProfileView(viewModel: ProfileViewModel(
                fetchUserDataUseCase: container.resolve(FetchUserDataUseCase.self),
                upsertStatusMessageUseCase: container.resolve(UpsertStatusMessageUseCase.self)
            ))
            .tabItem {
                Image(systemName: "person.crop.circle.fill")
                Text("프로필")
            }
        }
    }
}
