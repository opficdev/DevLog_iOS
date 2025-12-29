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
                appleAuthService: container.resolve(AppleAuthenticationServiceImpl.self),
                githubAuthService: container.resolve(GithubAuthenticationService.self),
                googleAuthService: container.resolve(GoogleAuthenticationService.self)
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

        container.register(SignInUseCase.self, name: "SignInWithAppleUseCaseImpl") {
            SignInWithAppleUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(SignInUseCase.self, name: "SignInWithGithubUseCaseImpl") {
            SignInWithGithubUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(SignInUseCase.self, name: "SignInWithGoogleUseCaseImpl") {
            SignInWithGoogleUseCaseImpl(container.resolve(AuthenticationRepository.self))
        }

        container.register(UpsertTodoUseCase.self) {
            UpsertTodoUseCaseImpl(container.resolve(TodoRepository.self))
        }
    }
}
