//
//  InfraAssembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

final class InfraAssembler: Assembler {
    func assemble(_ container: any DIContainer) {
        container.register(
            AuthenticationService.self,
            name: "AppleAuthenticationService"
        ) {
            AppleAuthenticationService()
        }

        container.register(
            AuthenticationService.self,
            name: "GithubAuthenticationService"
        ) {
            GithubAuthenticationService()
        }

        container.register(
            AuthenticationService.self,
            name: "GoogleAuthenticationService"
        ) {
            GoogleAuthenticationService()
        }

        container.register(AuthService.self) {
            AuthService()
        }

        container.register(TodoService.self) {
            TodoService()
        }

        container.register(UserService.self) {
            UserService()
        }

        container.register(PushNotificationService.self) {
            PushNotificationService()
        }

        container.register(WebPageService.self) {
            WebPageService()
        }

        container.register(WebPageMetadataService.self) {
            WebPageMetadataService()
        }

        container.register(NWPathConnectivityProvider.self) {
            NWPathConnectivityProvider()
        }
    }
}
