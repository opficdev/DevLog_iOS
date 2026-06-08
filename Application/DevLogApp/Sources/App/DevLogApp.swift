//
//  DevLogApp.swift
//  DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI
import DevLogCore
import DevLogData
import DevLogDomain
import DevLogPresentation
import DevLogWidget

@main
struct DevLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.diContainer) var container: DIContainer
    @Environment(\.scenePhase) var scenePhase
    @State private var windowEvent = TodoEditorWindowEvent()

    init() {
        AppAssembler().assemble(AppDIContainer.shared)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                sessionUseCase: container.resolve(ObserveAuthSessionUseCase.self),
                networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
                systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
                trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
                signInUseCase: container.resolve(SignInUseCase.self),
                widgetURLTab: { MainTab(widgetURL: $0) },
                windowEvent: windowEvent,
                pushNotificationTodoIdPublisher: PushNotificationRoute.shared.observe(),
                clearPushNotificationRoute: { PushNotificationRoute.shared.clear() }
            )
            .autocorrectionDisabled()
            .onChange(of: scenePhase) { _, phase in
                guard phase == .background else { return }
                container.resolve(WidgetSyncEventBus.self).publish(.syncRequested)
            }
        }
        WindowGroup(id: TodoEditorWindowValue.sceneId, for: TodoEditorWindowValue.self) { value in
            if let value = value.wrappedValue {
                TodoEditorWindowView(
                    value: value,
                    windowEvent: windowEvent
                )
                .autocorrectionDisabled()
            } else {
                ContentUnavailableView(
                    String(localized: "todo_edit"),
                    systemImage: "square.and.pencil"
                )
            }
        }
    }
}
