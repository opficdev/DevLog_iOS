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

        container.register(TodoRepository.self) {
            TodoRepositoryImpl(
                todoService: container.resolve(TodoService.self)
            )
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

        container.register(RestoreAuthUseCase.self) {
            RestoreAuthUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(UpsertTodoUseCase.self) {
            UpsertTodoUseCaseImpl(container.resolve(TodoRepository.self))
        }
    }
}
