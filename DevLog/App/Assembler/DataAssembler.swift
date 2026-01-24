//
//  DataAssembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

final class DataAssembler: Assembler {
    func assemble(_ container: any DIContainer) {
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
                userService: container.resolve(UserService.self)
            )
        }

        container.register(TodoRepository.self) {
            TodoRepositoryImpl(
                authService: container.resolve(AuthService.self),
                todoService: container.resolve(TodoService.self)
            )
        }

        container.register(AuthSessionRepository.self) {
            AuthSessionRepositoryImpl(authService: container.resolve(AuthService.self))
        }

        container.register(UserDataRepository.self) {
            UserDataRepositoryImpl(userService: container.resolve(UserService.self))
        }
    }
}
