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
    @AppStorage("theme") var theme: SystemTheme = .automatic
    @Environment(\.diContainer) var container: DIContainer

    init() {
        AppAssembler().assemble(AppDIContainer.shared)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: RootViewModel(
                    sessionUseCase: container.resolve(AuthSessionUseCase.self),
                    signOutUseCase: container.resolve(SignOutUseCase.self)
                ))
            .preferredColorScheme(theme.colorScheme)
        }
    }
}
