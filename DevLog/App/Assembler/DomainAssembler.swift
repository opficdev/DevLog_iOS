//
//  DomainAssembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

final class DomainAssembler: Assembler {
    func assemble(_ container: DIContainer) {
        registerRepositories(container)
        registerUseCases(container)
    }

    func registerRepositories(_ container: any DIContainer) {
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

    func registerUseCases(_ container: any DIContainer) {
        container.register(FetchPinnedTodosUseCase.self) {
            FetchPinnedTodosUseCaseImpl(container.resolve(TodoRepository.self))
        }

        container.register(SignInUseCase.self) {
            SignInUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(SignOutUseCase.self) {
            SignOutUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(DeleteAuthUseCase.self) {
            DeleteAuthUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(UpsertTodoUseCase.self) {
            UpsertTodoUseCaseImpl(container.resolve(TodoRepository.self))
        }

        container.register(AuthSessionUseCase.self) {
            AuthSessionUseCaseImpl(container.resolve(AuthSessionRepository.self))
        }

        container.register(FetchUserDataUseCase.self) {
            FetchUserDataUseCaseImpl(container.resolve(UserDataRepository.self))
        }
    }
}
