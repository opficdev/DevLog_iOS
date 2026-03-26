//
//  DevLogApp.swift
//  DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI

@main
struct DevLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.diContainer) var container: DIContainer

    init() {
        AppAssembler().assemble(AppDIContainer.shared)
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: RootViewModel(
                sessionUseCase: container.resolve(ObserveAuthSessionUseCase.self),
                networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
                systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self)
            ))
            .autocorrectionDisabled()
        }
    }
}
