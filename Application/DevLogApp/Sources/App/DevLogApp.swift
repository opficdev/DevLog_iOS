//
//  DevLogApp.swift
//  DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI
import DevLogCore
import DevLogDomain
import DevLogPresentation
import DevLogWidgetCore

@main
struct DevLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.diContainer) var container: DIContainer
    @Environment(\.scenePhase) var scenePhase

    init() {
        AppAssembler().assemble(AppDIContainer.shared)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                sessionUseCase: container.resolve(ObserveAuthSessionUseCase.self),
                networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
                systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
                widgetURLTab: { MainTab(widgetURL: $0) },
                pushNotificationTodoIdPublisher: PushNotificationRoute.shared.observe(),
                clearPushNotificationRoute: { PushNotificationRoute.shared.clear() }
            )
            .autocorrectionDisabled()
            .onChange(of: scenePhase) { _, phase in
                guard phase == .background else { return }
                container.resolve(WidgetSyncEventBus.self).publish(.syncRequested)
            }
        }
    }
}
