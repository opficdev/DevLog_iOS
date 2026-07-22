//
//  InfraAssembler.swift
//  Infra
//
//  Created by 최윤진 on 12/7/25.
//

import Core
import Data

public final class InfraAssembler: Assembler {
    public init() { }

    public func assemble(_ container: any DIContainer) {
        container.register(FirebaseAppService.self) {
            FirebaseAppServiceImpl()
        }

        container.register(AppVersionConfigurationService.self) {
            RemoteConfigAppVersionServiceImpl()
        }

        container.register(AnalyticsService.self) {
            FirebaseAnalyticsServiceImpl()
        }

        container.register(PushMessagingService.self) {
            PushMessagingServiceImpl()
        }

        container.register(
            AuthenticationService.self,
            name: "AppleAuthenticationService"
        ) {
            AppleAuthenticationServiceImpl()
        }

        container.register(
            AuthenticationService.self,
            name: "GithubAuthenticationService"
        ) {
            GithubAuthenticationServiceImpl()
        }

        container.register(
            AuthenticationService.self,
            name: "GoogleAuthenticationService"
        ) {
            GoogleAuthenticationServiceImpl()
        }

        container.register(AuthService.self) {
            AuthServiceImpl()
        }

        container.register(TodoService.self) {
            TodoServiceImpl()
        }

        container.register(TodoCategoryService.self) {
            TodoCategoryServiceImpl()
        }

        container.register(UserService.self) {
            UserServiceImpl()
        }

        container.register(ProfileImageDataService.self) {
            ProfileImageDataServiceImpl()
        }

        container.register(PushNotificationService.self) {
            PushNotificationServiceImpl()
        }

        container.register(WebPageService.self) {
            WebPageServiceImpl()
        }

        container.register(WebPageMetadataService.self) {
            WebPageMetadataServiceImpl(
                store: container.resolve(WebPageImageStore.self)
            )
        }

        container.register(NWPathConnectivityProvider.self) {
            NWPathConnectivityProviderImpl()
        }
    }
}
