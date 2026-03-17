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
                addWebPageUseCase: container.resolve(AddWebPageUseCase.self),
                deleteWebPageUseCase: container.resolve(DeleteWebPageUseCase.self),
                undoDeleteWebPageUseCase: container.resolve(UndoDeleteWebPageUseCase.self),
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
                fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
                upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                fetchTodayDisplayOptionsUseCase: container.resolve(FetchTodayDisplayOptionsUseCase.self),
                updateTodayDisplayOptionsUseCase: container.resolve(UpdateTodayDisplayOptionsUseCase.self)
            ))
            .tabItem {
                Image(systemName: "sun.max.fill")
                Text("오늘")
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
                Text("알림")
            }
            .badge(viewModel.state.unreadPushCount)
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
        .alert(
            viewModel.state.alertTitle,
            isPresented: Binding(
                get: { viewModel.state.showAlert },
                set: { viewModel.send(.setAlert($0)) }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
    }
}
