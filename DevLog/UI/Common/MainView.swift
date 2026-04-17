//
//  MainView.swift
//  DevLog
//
//  Created by opfic on 5/8/25.
//

import SwiftUI

struct MainView: View {
    @Environment(\.diContainer) var container: DIContainer
    @State var viewModel: MainViewModel

    var body: some View {
        TabView {
            HomeView(viewModel: HomeViewModel(
                fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
                updatePreferencesUseCase: container.resolve(UpdateTodoCategoryPreferencesUseCase.self),
                addWebPageUseCase: container.resolve(AddWebPageUseCase.self),
                deleteWebPageUseCase: container.resolve(DeleteWebPageUseCase.self),
                undoDeleteWebPageUseCase: container.resolve(UndoDeleteWebPageUseCase.self),
                upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                fetchWebPagesUseCase: container.resolve(FetchWebPagesUseCase.self),
                networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self)
            ))
            .tabItem {
                Image(systemName: "house.fill")
                Text(String(localized: "nav_home"))
            }
            TodayView(viewModel: TodayViewModel(
                fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
                upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                fetchTodayDisplayOptionsUseCase: container.resolve(FetchTodayDisplayOptionsUseCase.self),
                updateTodayDisplayOptionsUseCase: container.resolve(UpdateTodayDisplayOptionsUseCase.self)
            ))
            .tabItem {
                Image(systemName: "sun.max.fill")
                Text(String(localized: "nav_today"))
            }
            PushNotificationListView(viewModel: PushNotificationListViewModel(
                fetchUseCase: container.resolve(FetchPushNotificationsUseCase.self),
                deleteUseCase: container.resolve(DeletePushNotificationUseCase.self),
                undoDeleteUseCase: container.resolve(UndoDeletePushNotificationUseCase.self),
                toggleReadUseCase: container.resolve(TogglePushNotificationReadUseCase.self),
                fetchQueryUseCase: container.resolve(FetchPushNotificationQueryUseCase.self),
                updateQueryUseCase: container.resolve(UpdatePushNotificationQueryUseCase.self)
            ))
            .tabItem {
                Image(systemName: "bell.fill")
                Text(String(localized: "nav_notifications"))
            }
            .badge(viewModel.state.unreadPushCount)
            ProfileView(viewModel: ProfileViewModel(
                fetchUserDataUseCase: container.resolve(FetchUserDataUseCase.self),
                fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                upsertStatusMessageUseCase: container.resolve(UpsertStatusMessageUseCase.self),
                networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
                fetchHeatmapActivityTypesUseCase: container.resolve(FetchHeatmapActivityTypesUseCase.self),
                updateHeatmapActivityTypesUseCase: container.resolve(UpdateHeatmapActivityTypesUseCase.self)
            ))
            .tabItem {
                Image(systemName: "person.crop.circle.fill")
                Text(String(localized: "nav_profile"))
            }
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
        .alert(
            viewModel.state.alertTitle,
            isPresented: Binding(
                get: { viewModel.state.showAlert },
                set: { viewModel.send(.setAlert($0)) }
            )
        ) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
    }
}
