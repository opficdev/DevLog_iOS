//
//  MainView.swift
//  DevLog
//
//  Created by opfic on 5/8/25.
//

import SwiftUI

struct MainView: View {
    @Environment(\.diContainer) var container: DIContainer
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var viewModel: MainViewModel
    @Binding var selectedTab: MainTab

    var body: some View {
        content
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

    @ViewBuilder
    private var content: some View {
        if isCompactLayout {
            tabView
        } else {
            sidebarView
        }
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var sidebarSelection: Binding<MainTab?> {
        Binding(
            get: { selectedTab },
            set: { tab in
                if let tab {
                    selectedTab = tab
                }
            }
        )
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            homeView
                .tabItem {
                    tabLabel(.home)
                }
                .tag(MainTab.home)

            todayView
                .tabItem {
                    tabLabel(.today)
                }
                .tag(MainTab.today)

            notificationView
                .tabItem {
                    tabLabel(.notification)
                }
                .badge(viewModel.state.unreadPushCount)
                .tag(MainTab.notification)

            profileView
                .tabItem {
                    tabLabel(.profile)
                }
                .tag(MainTab.profile)
        }
    }

    @ViewBuilder
    private var sidebarView: some View {
        switch selectedTab.mainTabSplitStyle {
        case .detailOnly:
            NavigationSplitView {
                mainSidebar
            } detail: {
                selectedTabView
            }
        case .contentDetail:
            switch selectedTab {
            case .home:
                NavigationSplitView {
                    mainSidebar
                } content: {
                    homeView
                } detail: {
                    EmptyView()
                }
            case .today:
                NavigationSplitView {
                    mainSidebar
                } content: {
                    todayView
                } detail: {
                    EmptyView()
                }
            case .notification:
                let viewModel = makePushNotificationListViewModel()
                NavigationSplitView {
                    mainSidebar
                } content: {
                    PushNotificationListView(
                        viewModel: viewModel,
                        isCompactLayout: isCompactLayout
                    )
                } detail: {
                    Group {
                        if let todoId = viewModel.state.selectedTodoId?.id {
                            TodoDetailView(viewModel: TodoDetailViewModel(
                                fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                                fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                                upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                                todoId: todoId,
                                showEditButton: false
                            ))
                            .id(todoId)
                        } else {
                            ContentUnavailableView(
                                String(localized: "push_notifications_select_detail"),
                                systemImage: "bell.badge"
                            )
                            .background(Color(.secondarySystemBackground))
                        }
                    }
                    .background(Color(.secondarySystemBackground).ignoresSafeArea())
                }
            case .profile:
                NavigationSplitView {
                    mainSidebar
                } detail: {
                    selectedTabView
                }
            }
        }
    }

    private var mainSidebar: some View {
        List(selection: sidebarSelection) {
            sidebarRow(.home)
            sidebarRow(.today)
            sidebarRow(.notification)
            sidebarRow(.profile)
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var selectedTabView: some View {
        switch selectedTab {
        case .home:
            homeView
        case .today:
            todayView
        case .notification:
            notificationView
        case .profile:
            profileView
        }
    }

    @ViewBuilder
    private func sidebarRow(_ tab: MainTab) -> some View {
        if tab == .notification {
            tabLabel(tab)
                .badge(viewModel.state.unreadPushCount)
                .tag(tab)
        } else {
            tabLabel(tab)
                .tag(tab)
        }
    }

    private func tabLabel(_ tab: MainTab) -> some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(systemName: tab.symbolName)
        }
    }

    private var homeView: some View {
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
    }

    private var todayView: some View {
        TodayView(viewModel: TodayViewModel(
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            fetchTodayDisplayOptionsUseCase: container.resolve(FetchTodayDisplayOptionsUseCase.self),
            updateTodayDisplayOptionsUseCase: container.resolve(UpdateTodayDisplayOptionsUseCase.self)
        ))
    }

    private var notificationView: some View {
        PushNotificationListView(
            viewModel: makePushNotificationListViewModel(),
            isCompactLayout: isCompactLayout
        )
    }

    private func makePushNotificationListViewModel() -> PushNotificationListViewModel {
        PushNotificationListViewModel(
            fetchUseCase: container.resolve(FetchPushNotificationsUseCase.self),
            deleteUseCase: container.resolve(DeletePushNotificationUseCase.self),
            undoDeleteUseCase: container.resolve(UndoDeletePushNotificationUseCase.self),
            toggleReadUseCase: container.resolve(TogglePushNotificationReadUseCase.self),
            fetchQueryUseCase: container.resolve(FetchPushNotificationQueryUseCase.self),
            updateQueryUseCase: container.resolve(UpdatePushNotificationQueryUseCase.self)
        )
    }

    private var profileView: some View {
        ProfileView(viewModel: ProfileViewModel(
            fetchUserDataUseCase: container.resolve(FetchUserDataUseCase.self),
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            upsertStatusMessageUseCase: container.resolve(UpsertStatusMessageUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
            fetchHeatmapActivityTypesUseCase: container.resolve(FetchHeatmapActivityTypesUseCase.self),
            updateHeatmapActivityTypesUseCase: container.resolve(UpdateHeatmapActivityTypesUseCase.self)
        ))
    }
}

private enum MainTabSplitStyle {
    case detailOnly
    case contentDetail
}

private extension MainTab {
    var mainTabSplitStyle: MainTabSplitStyle {
        switch self {
        case .home, .today, .notification:
            .contentDetail
        case .profile:
            .detailOnly
        }
    }

    var title: String {
        switch self {
        case .home:
            String(localized: "nav_home")
        case .today:
            String(localized: "nav_today")
        case .notification:
            String(localized: "nav_notifications")
        case .profile:
            String(localized: "nav_profile")
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            "house.fill"
        case .today:
            "sun.max.fill"
        case .notification:
            "bell.fill"
        case .profile:
            "person.crop.circle.fill"
        }
    }
}
