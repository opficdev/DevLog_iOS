//
//  DataAssembler.swift
//  Data
//
//  Created by 최윤진 on 12/7/25.
//

import Core
import Domain

public final class DataAssembler: Assembler {
    public init() { }

    public func assemble(_ container: any DIContainer) {
        container.register(AuthenticationRepository.self) {
            AuthenticationRepositoryImpl(
                authService: container.resolve(AuthService.self),
                appleAuthService: container.resolve(
                    AuthenticationService.self,
                    name: "AppleAuthenticationService"
                ),
                githubAuthService: container.resolve(
                    AuthenticationService.self,
                    name: "GithubAuthenticationService"
                ),
                googleAuthService: container.resolve(
                    AuthenticationService.self,
                    name: "GoogleAuthenticationService"
                ),
                userService: container.resolve(UserService.self),
                widgetSnapshotUpdater: container.resolve(WidgetSnapshotUpdater.self)
            )
        }

        container.register(TodoMutationEventBus.self) {
            TodoMutationEventBusImpl()
        }

        container.register(TodoRepository.self) {
            TodoRepositoryImpl(
                todoService: container.resolve(TodoService.self),
                todoCategoryService: container.resolve(TodoCategoryService.self),
                store: container.resolve(MemoryCacheStore.self),
                updater: container.resolve(WidgetSnapshotUpdater.self),
                eventBus: container.resolve(TodoMutationEventBus.self)
            )
        }

        container.register(WidgetTodoSnapshotRepository.self) {
            WidgetTodoSnapshotRepositoryImpl(todoService: container.resolve(TodoService.self))
        }

        container.register(TodoCategoryRepository.self) {
            TodoCategoryRepositoryImpl(
                todoCategoryService: container.resolve(TodoCategoryService.self),
                store: container.resolve(MemoryCacheStore.self)
            )
        }

        container.register(AuthSessionRepository.self) {
            AuthSessionRepositoryImpl(
                authService: container.resolve(AuthService.self),
                todoCategoryService: container.resolve(TodoCategoryService.self),
                store: container.resolve(MemoryCacheStore.self),
                provider: container.resolve(AuthSessionStateProvider.self)
            )
        }

        container.register(NetworkConnectivityRepository.self) {
            NetworkConnectivityRepositoryImpl(
                connectivityProvider: container.resolve(NWPathConnectivityProvider.self)
            )
        }

        container.register(AuthDataRepository.self) {
            AuthDataRepositoryImpl(
                authService: container.resolve(AuthService.self),
                appleAuthService: container.resolve(
                    AuthenticationService.self,
                    name: "AppleAuthenticationService"
                ),
                githubAuthService: container.resolve(
                    AuthenticationService.self,
                    name: "GithubAuthenticationService"
                ),
                googleAuthService: container.resolve(
                    AuthenticationService.self,
                    name: "GoogleAuthenticationService"
                )
            )
        }

        container.register(UserDataRepository.self) {
            UserDataRepositoryImpl(userService: container.resolve(UserService.self))
        }

        container.register(ProfileImageDataRepository.self) {
            ProfileImageDataRepositoryImpl(
                service: container.resolve(ProfileImageDataService.self),
                store: container.resolve(MemoryCacheStore.self)
            )
        }

        container.register(AnalyticsRepository.self) {
            AnalyticsRepositoryImpl(
                analyticsService: container.resolve(AnalyticsService.self)
            )
        }

        container.register(PushNotificationRepository.self) {
            PushNotificationRepositoryImpl(
                pushNotificationService: container.resolve(PushNotificationService.self),
                todoCategoryService: container.resolve(TodoCategoryService.self),
                store: container.resolve(MemoryCacheStore.self)
            )
        }

        container.register(WebPageRepository.self) {
            WebPageRepositoryImpl(
                authService: container.resolve(AuthService.self),
                metadataService: container.resolve(WebPageMetadataService.self),
                webPageService: container.resolve(WebPageService.self)
            )
        }

        container.register(WebPageImageRepository.self) {
            WebPageImageRepositoryImpl(
                authService: container.resolve(AuthService.self),
                store: container.resolve(WebPageImageStore.self)
            )
        }

        container.register(UserPreferencesRepository.self) {
            UserPreferencesRepositoryImpl(
                store: container.resolve(UserDefaultsStore.self),
                themeStore: container.resolve(ThemeStore.self),
                widgetSnapshotPreferenceStore: container.resolve(WidgetSnapshotPreferenceStore.self),
                widgetSyncEventBus: container.resolve(WidgetSyncEventBus.self)
            )
        }
    }
}
