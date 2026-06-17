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
                        selectedTab: $store.selectedMainTab
                    )
                } else {
                    LoginView(signInUseCase: container.resolve(SignInUseCase.self))
                }
            }
        }
        .preferredColorScheme(store.theme.colorScheme)
        .onAppear { store.send(.view(.onAppear)) }
        .onOpenURL { url in
            guard let mainTab = widgetURLTab(url) else { return }
            store.send(.view(.openWidgetRoute(mainTab)))
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.sheet, action: \.sheet)) { sheetStore in
            NavigationStack {
                TodoDetailView(store: Store(
                    initialState: TodoDetailFeature.State(todoId: sheetStore.todoId, showEditButton: false)
                ) {
                    TodoDetailFeature()
                } withDependencies: {
                    $0.fetchTodoByIdUseCase = container.resolve(FetchTodoByIdUseCase.self)
                    $0.fetchReferenceItemsUseCase = container.resolve(FetchReferenceItemsUseCase.self)
                })
                .toolbar {
                    ToolbarLeadingButton {
                        sheetStore.send(.tapCloseButton)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .presentationDragIndicator(.visible)
        }
        .onReceive(pushNotificationTodoIdPublisher) { todoId in
            store.send(.view(.presentTodoDetail(todoId)))
            clearPushNotificationRoute()
        }
    }
}
