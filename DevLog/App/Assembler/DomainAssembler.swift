//
//  DomainAssembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

final class DomainAssembler: Assembler {
    func assemble(_ container: DIContainer) {
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

        container.register(UpsertStatusMessageUseCase.self) {
            UpsertStatusMessageUseCaseImpl(container.resolve(UserDataRepository.self))
        }
    }
}
