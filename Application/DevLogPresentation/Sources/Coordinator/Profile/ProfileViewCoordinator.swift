//
//  ProfileViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/21/26.
//

import Foundation
import DevLogCore
import DevLogDomain

@MainActor
@Observable
public final class ProfileViewCoordinator {
    public let viewModel: ProfileViewModel
    public let settingViewModel: SettingViewModel
    public var router = NavigationRouter<ProfileRoute>()
    private let container: DIContainer

    public init(container: DIContainer) {
        self.container = container
        self.viewModel = ProfileViewModel(
            fetchUserDataUseCase: container.resolve(FetchUserDataUseCase.self),
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            upsertStatusMessageUseCase: container.resolve(UpsertStatusMessageUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
            fetchHeatmapActivityTypesUseCase: container.resolve(FetchHeatmapActivityTypesUseCase.self),
            updateHeatmapActivityTypesUseCase: container.resolve(UpdateHeatmapActivityTypesUseCase.self)
        )
        self.settingViewModel = SettingViewModel(
            deleteAuthUseCase: container.resolve(DeleteAuthUseCase.self),
            signOutUseCase: container.resolve(SignOutUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
            systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
            updateSystemThemeUseCase: container.resolve(UpdateSystemThemeUseCase.self),
            fetchWebPageImageDirSizeUseCase: container.resolve(FetchWebPageImageDirSizeUseCase.self),
            clearWebPageImageDirectoryUseCase: container.resolve(ClearWebPageImageDirectoryUseCase.self)
        )
    }

    public func fetchData() {
        viewModel.send(.fetchData)
    }

    public func makeAccountViewModel() -> AccountViewModel {
        AccountViewModel(
            fetchProvidersUseCase: container.resolve(FetchAuthProvidersUseCase.self),
            linkProviderUseCase: container.resolve(LinkAuthProviderUseCase.self),
            unlinkProviderUseCase: container.resolve(UnlinkAuthProviderUseCase.self)
        )
    }

    public func makePushNotificationSettingsViewModel() -> PushNotificationSettingsViewModel {
        PushNotificationSettingsViewModel(
            fetchPushSettingsUseCase: container.resolve(FetchPushSettingsUseCase.self),
            updatePushSettingsUseCase: container.resolve(UpdatePushSettingsUseCase.self)
        )
    }

    public func makeTodoDetailViewModel(todoId: String) -> TodoDetailViewModel {
        TodoDetailViewModel(
            fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
            todoId: todoId,
            showEditButton: false
        )
    }
}
