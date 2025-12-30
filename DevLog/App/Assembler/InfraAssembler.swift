//
//  InfraAssembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

final class InfraAssembler: @MainActor Assembler {
    @MainActor
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

        container.register(TodoService.self) {
            TodoService()
        }
    }
}
