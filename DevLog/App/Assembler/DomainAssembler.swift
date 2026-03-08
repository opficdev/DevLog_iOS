//
//  DomainAssembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

final class DomainAssembler: Assembler {
    func assemble(_ container: DIContainer) {
        registerAuthUseCases(container)
        registerAuthProviderUseCases(container)
        registerTodoUseCases(container)
        registerUserDataUseCases(container)
        registerPushNotificationUseCases(container)
        registerWebPageUseCases(container)
        registerUserPreferencesUseCases(container)
    }
}

private extension DomainAssembler {
    func registerAuthUseCases(_ container: DIContainer) {
        container.register(SignInUseCase.self) {
            SignInUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(SignOutUseCase.self) {
            SignOutUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(DeleteAuthUseCase.self) {
            DeleteAuthUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(AuthSessionUseCase.self) {
            AuthSessionUseCaseImpl(container.resolve(AuthSessionRepository.self))
        }
    }

    func registerAuthProviderUseCases(_ container: DIContainer) {
        container.register(FetchAuthProvidersUseCase.self) {
            FetchAuthProvidersUseCaseImpl(container.resolve(AuthDataRepository.self))
        }

        container.register(LinkAuthProviderUseCase.self) {
            LinkAuthProviderUseCaseImpl(container.resolve(AuthDataRepository.self))
        }

        container.register(UnlinkAuthProviderUseCase.self) {
            UnlinkAuthProviderUseCaseImpl(container.resolve(AuthDataRepository.self))
        }
    }

    func registerTodoUseCases(_ container: DIContainer) {
        container.register(FetchTodoByIdUseCase.self) {
            FetchTodoByIdUseCaseImpl(container.resolve(TodoRepository.self))
        }

        container.register(FetchTodosUseCase.self) {
            FetchTodosUseCaseImpl(container.resolve(TodoRepository.self))
        }

        container.register(UpsertTodoUseCase.self) {
            UpsertTodoUseCaseImpl(container.resolve(TodoRepository.self))
        }

        container.register(DeleteTodoUseCase.self) {
            DeleteTodoUseCaseImpl(container.resolve(TodoRepository.self))
        }
    }

    func registerUserDataUseCases(_ container: DIContainer) {
        container.register(FetchUserDataUseCase.self) {
            FetchUserDataUseCaseImpl(container.resolve(UserDataRepository.self))
        }

        container.register(UpsertStatusMessageUseCase.self) {
            UpsertStatusMessageUseCaseImpl(container.resolve(UserDataRepository.self))
        }
    }

    func registerPushNotificationUseCases(_ container: DIContainer) {
        container.register(FetchPushSettingsUseCase.self) {
            FetchPushNotificationSettingsUseCaseImpl(container.resolve(PushNotificationRepository.self))
        }

        container.register(UpdatePushSettingsUseCase.self) {
            UpdatePushSettingsUseCaseImpl(container.resolve(PushNotificationRepository.self))
        }

        container.register(DeletePushNotificationUseCase.self) {
            DeletePushNotificationUseCaseImpl(container.resolve(PushNotificationRepository.self))
        }

        container.register(FetchPushNotificationsUseCase.self) {
            FetchPushNotificationsUseCaseImpl(container.resolve(PushNotificationRepository.self))
        }

        container.register(TogglePushNotificationReadUseCase.self) {
            TogglePushNotificationReadUseCaseImpl(container.resolve(PushNotificationRepository.self))
        }
    }

    func registerWebPageUseCases(_ container: DIContainer) {
        container.register(FetchWebPagesUseCase.self) {
            FetchWebPagesUseCaseImpl(container.resolve(WebPageRepository.self))
        }

        container.register(AddWebPageUseCase.self) {
            AddWebPageUseCaseImpl(container.resolve(WebPageRepository.self))
        }

        container.register(DeleteWebPageUseCase.self) {
            DeleteWebPageUseCaseImpl(container.resolve(WebPageRepository.self))
        }
    }

    func registerUserPreferencesUseCases(_ container: DIContainer) {
        container.register(ObserveSystemThemeUseCase.self) {
            ObserveSystemThemeUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(UpdateSystemThemeUseCase.self) {
            UpdateSystemThemeUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(FetchFirstLaunchUseCase.self) {
            FetchFirstLaunchUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(UpdateFirstLaunchUseCase.self) {
            UpdateFirstLaunchUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(FetchRecentSearchQueriesUseCase.self) {
            FetchRecentSearchQueriesUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(UpdateRecentSearchQueriesUseCase.self) {
            UpdateRecentSearchQueriesUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(FetchPushNotificationQueryUseCase.self) {
            FetchPushNotificationQueryUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(UpdatePushNotificationQueryUseCase.self) {
            UpdatePushNotificationQueryUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(FetchProfileHeatmapActivityTypesUseCase.self) {
            FetchProfileHeatmapActivityTypesUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(UpdateProfileHeatmapActivityTypesUseCase.self) {
            UpdateProfileHeatmapActivityTypesUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(FetchTodayDisplayOptionsUseCase.self) {
            FetchTodayDisplayOptionsUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }

        container.register(UpdateTodayDisplayOptionsUseCase.self) {
            UpdateTodayDisplayOptionsUseCaseImpl(container.resolve(UserPreferencesRepository.self))
        }
    }
}
