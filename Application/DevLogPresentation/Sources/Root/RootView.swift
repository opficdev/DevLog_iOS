//
//  RootView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/2/25.
//

import SwiftUI
import Combine
import ComposableArchitecture
import DevLogCore
import DevLogDomain

public struct RootView: View {
    @Environment(\.diContainer) var container: DIContainer
    @State private var store: StoreOf<RootFeature>
    @State private var selectedRoute: Route?
    @State private var selectedMainTab = MainTab.home
    private let widgetURLTab: (URL) -> MainTab?
    private let windowEvent: TodoEditorWindowEvent
    private let pushNotificationTodoIdPublisher: AnyPublisher<String, Never>
    private let clearPushNotificationRoute: () -> Void

    public init(
        sessionUseCase: ObserveAuthSessionUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase,
        systemThemeUseCase: ObserveSystemThemeUseCase,
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase,
        widgetURLTab: @escaping (URL) -> MainTab?,
        windowEvent: TodoEditorWindowEvent,
        pushNotificationTodoIdPublisher: AnyPublisher<String, Never>,
        clearPushNotificationRoute: @escaping () -> Void
    ) {
        self._store = State(initialValue: Store(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.observeAuthSessionUseCase = sessionUseCase
            $0.networkConnectivityUseCase = networkConnectivityUseCase
            $0.systemThemeUseCase = systemThemeUseCase
            $0.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
        })
        self.widgetURLTab = widgetURLTab
        self.windowEvent = windowEvent
        self.pushNotificationTodoIdPublisher = pushNotificationTodoIdPublisher
        self.clearPushNotificationRoute = clearPushNotificationRoute
    }

    public var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = store.signIn {
                if signIn {
                    MainView(
                        container: container,
                        windowEvent: windowEvent,
                        selectedTab: $selectedMainTab
                    )
                } else {
                    LoginView(signInUseCase: container.resolve(SignInUseCase.self))
                }
            }
        }
        .preferredColorScheme(store.theme.colorScheme)
        .onAppear { store.send(.view(.onAppear)) }
        .onChange(of: store.signIn) { _, value in
            guard let value else { return }
            if value {
                selectedMainTab = .home
            }
        }
        .onOpenURL { url in
            guard let mainTab = widgetURLTab(url) else { return }
            switch store.signIn {
            case .some(false):
                break
            case .some(true):
                selectedMainTab = mainTab
            case .none:
                break
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $selectedRoute) { route in
            switch route {
            case .todoDetail(let todoId):
                NavigationStack {
                    TodoDetailView(store: Store(
                        initialState: TodoDetailFeature.State(todoId: todoId, showEditButton: false)
                    ) {
                        TodoDetailFeature()
                    } withDependencies: {
                        $0.fetchTodoByIdUseCase = container.resolve(FetchTodoByIdUseCase.self)
                        $0.fetchReferenceItemsUseCase = container.resolve(FetchReferenceItemsUseCase.self)
                    })
                    .toolbar {
                        ToolbarLeadingButton {
                            selectedRoute = nil
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(pushNotificationTodoIdPublisher) { todoId in
            selectedRoute = .todoDetail(todoId)
            clearPushNotificationRoute()
        }
    }
}

private enum Route: Equatable, Identifiable {
    case todoDetail(String)

    var id: String {
        switch self {
        case .todoDetail(let todoId):
            return "todo:\(todoId)"
        }
    }
}
