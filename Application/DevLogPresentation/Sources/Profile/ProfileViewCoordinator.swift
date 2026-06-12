//
//  ProfileViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/21/26.
//

import Foundation
import ComposableArchitecture
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class ProfileViewCoordinator {
    let viewModel: ProfileViewModel
    let settingsViewModel: SettingsViewModel
    var router = NavigationRouter<ProfileRoute>()
    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
        self.viewModel = ProfileViewModel(
            fetchUserDataUseCase: container.resolve(FetchUserDataUseCase.self),
            fetchProfileImageDataUseCase: container.resolve(FetchProfileImageDataUseCase.self),
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            upsertStatusMessageUseCase: container.resolve(UpsertStatusMessageUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
            fetchHeatmapActivityTypesUseCase: container.resolve(FetchHeatmapActivityTypesUseCase.self),
            updateHeatmapActivityTypesUseCase: container.resolve(UpdateHeatmapActivityTypesUseCase.self)
        )
        self.settingsViewModel = SettingsViewModel(
            deleteAuthUseCase: container.resolve(DeleteAuthUseCase.self),
            signOutUseCase: container.resolve(SignOutUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
            systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
            updateSystemThemeUseCase: container.resolve(UpdateSystemThemeUseCase.self),
            fetchWebPageImageDirSizeUseCase: container.resolve(FetchWebPageImageDirSizeUseCase.self),
            clearWebPageImageDirectoryUseCase: container.resolve(ClearWebPageImageDirectoryUseCase.self)
        )
    }

    func fetchData() {
        viewModel.send(.fetchData)
    }

    func makeAccountStore() -> StoreOf<AccountFeature> {
        Store(initialState: AccountFeature.State()) {
            AccountFeature()
        } withDependencies: {
            $0.fetchAuthProvidersUseCase = self.container.resolve(FetchAuthProvidersUseCase.self)
            $0.linkAuthProviderUseCase = self.container.resolve(LinkAuthProviderUseCase.self)
            $0.unlinkAuthProviderUseCase = self.container.resolve(UnlinkAuthProviderUseCase.self)
        }
    }

    func makePushNotificationSettingsStore() -> StoreOf<PushNotificationSettingsFeature> {
        Store(initialState: PushNotificationSettingsFeature.State()) {
            PushNotificationSettingsFeature()
        } withDependencies: {
            $0.fetchPushSettingsUseCase = self.container.resolve(FetchPushSettingsUseCase.self)
            $0.updatePushSettingsUseCase = self.container.resolve(UpdatePushSettingsUseCase.self)
        }
    }

    func makeTodoDetailStore(todoId: String) -> StoreOf<TodoDetailFeature> {
        Store(
            initialState: TodoDetailFeature.State(
                todoId: todoId,
                showEditButton: false
            )
        ) {
            TodoDetailFeature()
        } withDependencies: {
            $0.fetchTodoByIdUseCase = self.container.resolve(FetchTodoByIdUseCase.self)
            $0.fetchReferenceItemsUseCase = self.container.resolve(FetchReferenceItemsUseCase.self)
        }
    }
}
