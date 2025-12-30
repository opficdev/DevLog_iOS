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
            RootView(viewModel: LoginViewModel(
                signInUseCase: container.resolve(SignInUseCase.self),
                signOutUseCase: container.resolve(SignOutUseCase.self),
                restoreUseCase: container.resolve(RestoreAuthUseCase.self)
            ))
            .preferredColorScheme(theme.colorScheme)
        }
    }
}
