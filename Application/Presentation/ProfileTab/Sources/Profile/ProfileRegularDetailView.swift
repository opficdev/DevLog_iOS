//
//  ProfileRegularDetailView.swift
//  ProfileTab
//
//  Created by opfic on 7/6/26.
//

import SwiftUI
import PresentationShared

public struct ProfileRegularDetailView: View {
    let coordinator: ProfileViewCoordinator

    public init(coordinator: ProfileViewCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        NavigationStack(path: Binding(
            get: { coordinator.router.detailPath },
            set: { coordinator.router.detailPath = $0 }
        )) {
            Group {
                if let route = coordinator.router.root {
                    profileDestinationView(route)
                } else {
                    ContentUnavailableView(
                        String(localized: "profile_select_detail"),
                        systemImage: "person.crop.circle"
                    )
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                profileDestinationView(route)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func profileDestinationView(_ route: ProfileRoute) -> some View {
        switch route {
        case .settings:
            SettingsView(store: coordinator.settingsStore)
                .environment(coordinator.router)
        case .activity(let todoId):
            TodoDetailView(store: coordinator.makeTodoDetailStore(todoId: todoId))
                .id(todoId)
        case .theme:
            @Bindable var settingsStore = coordinator.settingsStore
            ThemeView(theme: $settingsStore.theme)
        case .pushNotification:
            PushNotificationSettingsView(store: coordinator.makePushNotificationSettingsStore())
        case .account:
            AccountView(store: coordinator.makeAccountStore())
        }
    }
}
