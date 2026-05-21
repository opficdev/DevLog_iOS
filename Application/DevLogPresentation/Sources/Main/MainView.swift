//
//  MainView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/8/25.
//

import SwiftUI
import DevLogCore
import DevLogDomain

struct MainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var coordinator: MainViewCoordinator
    @State private var homeViewCoordinator: HomeViewCoordinator
    @State private var todayViewCoordinator: TodayViewCoordinator
    @State private var profileViewCoordinator: ProfileViewCoordinator
    @Binding var selectedTab: MainTab

    init(
        container: DIContainer,
        selectedTab: Binding<MainTab>
    ) {
        self._coordinator = State(initialValue: MainViewCoordinator(container: container))
        self._homeViewCoordinator = State(initialValue: HomeViewCoordinator(container: container))
        self._todayViewCoordinator = State(initialValue: TodayViewCoordinator(container: container))
        self._profileViewCoordinator = State(initialValue: ProfileViewCoordinator(container: container))
        self._selectedTab = selectedTab
    }

    var body: some View {
        Group {
            if isCompactLayout {
                tabView
            } else {
                sidebarView
            }
        }
        .onAppear {
            coordinator.mainViewModel.send(.onAppear)
        }
        .alert(
            coordinator.mainViewModel.state.alertTitle,
            isPresented: mainAlertPresented
        ) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(coordinator.mainViewModel.state.alertMessage)
        }
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
                .badge(coordinator.mainViewModel.state.unreadPushCount)
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
                    homeRegularDetailView
                }
                .environment(homeViewCoordinator.router)
            case .today:
                NavigationSplitView {
                    mainSidebar
                } content: {
                    todayView
                } detail: {
                    todayRegularDetailView
                }
            case .notification:
                NavigationSplitView {
                    mainSidebar
                } content: {
                    PushNotificationListView(
                        viewModel: coordinator.pushNotificationListViewModel,
                        todoIdToPresent: todoIdToPresent,
                        isCompactLayout: isCompactLayout
                    )
                } detail: {
                    Group {
                        if let todoId = coordinator.todoIdToPresent?.id {
                            TodoDetailView(
                                viewModel: coordinator.todoDetailViewModel(
                                    todoId: todoId,
                                    showEditButton: false
                                )
                            )
                            .id(todoId)
                        } else {
                            ContentUnavailableView(
                                String(localized: "push_notifications_select_detail"),
                                systemImage: "bell.badge"
                            )
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
                .badge(coordinator.mainViewModel.state.unreadPushCount)
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

    @ViewBuilder
    private var homeView: some View {
        Group {
            if isCompactLayout {
                NavigationStack(path: homeNavigationPath) {
                    homeContentView
                        .navigationDestination(for: HomeRoute.self) { homeRoute in
                            homeDestinationView(homeRoute)
                        }
                }
            } else {
                homeContentView
            }
        }
        .environment(homeViewCoordinator.router)
    }

    private var homeContentView: some View {
        HomeView(
            coordinator: homeViewCoordinator,
            isCompactLayout: isCompactLayout
        )
    }

    @ViewBuilder
    private var homeRegularDetailView: some View {
        NavigationStack(path: homeDetailPath) {
            Group {
                if let homeRoute = homeViewCoordinator.router.root {
                    homeDestinationView(homeRoute)
                } else {
                    ContentUnavailableView(
                        String(localized: "home_select_detail"),
                        systemImage: "house"
                    )
                }
            }
            .navigationDestination(for: HomeRoute.self) { homeRoute in
                homeDestinationView(homeRoute)
            }
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func homeDestinationView(_ homeRoute: HomeRoute) -> some View {
        switch homeRoute {
        case .category(let item):
            TodoListView(
                viewModel: coordinator.todoListViewModel(category: item.todoCategory)
            )
            .id(item.id)
        case .todo(let item):
            TodoDetailView(viewModel: coordinator.todoDetailViewModel(todoId: item.id))
            .id(item.id)
        case .webPage(let item):
            WebView(url: item.url)
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea()
                .toolbar(.hidden, for: .tabBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(item.title)
                            .bold()
                    }
            }
        }
    }

    @ViewBuilder
    private var todayView: some View {
        Group {
            if isCompactLayout {
                NavigationStack(path: todayNavigationPath) {
                    todayContentView
                        .navigationDestination(for: TodayRoute.self) { todayRoute in
                            todayDestinationView(todayRoute)
                        }
                }
            } else {
                todayContentView
            }
        }
    }

    private var todayContentView: some View {
        TodayView(
            coordinator: todayViewCoordinator,
            isCompactLayout: isCompactLayout
        )
    }

    @ViewBuilder
    private var todayRegularDetailView: some View {
        NavigationStack(path: todayDetailPath) {
            Group {
                if let todayRoute = todayViewCoordinator.router.root {
                    todayDestinationView(todayRoute)
                } else {
                    ContentUnavailableView(
                        String(localized: "today_select_detail"),
                        systemImage: "sun.max"
                    )
                }
            }
            .navigationDestination(for: TodayRoute.self) { todayRoute in
                todayDestinationView(todayRoute)
            }
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func todayDestinationView(_ todayRoute: TodayRoute) -> some View {
        switch todayRoute {
        case .todo(let item):
            TodoDetailView(viewModel: coordinator.todoDetailViewModel(todoId: item.id))
                .id(item.id)
        }
    }

    private var notificationView: some View {
        PushNotificationListView(
            viewModel: coordinator.pushNotificationListViewModel,
            todoIdToPresent: todoIdToPresent,
            isCompactLayout: isCompactLayout
        )
    }

    private var profileView: some View {
        ProfileView(coordinator: profileViewCoordinator)
    }
}

private extension MainView {
    var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var mainAlertPresented: Binding<Bool> {
        Binding(
            get: { coordinator.mainViewModel.state.showAlert },
            set: { coordinator.mainViewModel.send(.setAlert($0)) }
        )
    }

    var sidebarSelection: Binding<MainTab?> {
        Binding(
            get: { selectedTab },
            set: { tab in
                if let tab {
                    selectedTab = tab
                }
            }
        )
    }

    var todoIdToPresent: Binding<TodoIdItem?> {
        Binding(
            get: { coordinator.todoIdToPresent },
            set: { coordinator.todoIdToPresent = $0 }
        )
    }

    var homeNavigationPath: Binding<[HomeRoute]> {
        Binding(
            get: { homeViewCoordinator.router.path },
            set: { homeViewCoordinator.router.path = $0 }
        )
    }

    var homeDetailPath: Binding<[HomeRoute]> {
        Binding(
            get: { homeViewCoordinator.router.detailPath },
            set: { homeViewCoordinator.router.detailPath = $0 }
        )
    }

    var todayNavigationPath: Binding<[TodayRoute]> {
        Binding(
            get: { todayViewCoordinator.router.path },
            set: { todayViewCoordinator.router.path = $0 }
        )
    }

    var todayDetailPath: Binding<[TodayRoute]> {
        Binding(
            get: { todayViewCoordinator.router.detailPath },
            set: { todayViewCoordinator.router.detailPath = $0 }
        )
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
