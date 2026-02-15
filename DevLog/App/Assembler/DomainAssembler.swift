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

        container.register(FetchTodoUseCase.self) {
            FetchTodoUseCaseImpl(container.resolve(TodoRepository.self))
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
        
        container.register(DeleteTodoUseCase.self) {
            DeleteTodoUseCaseImpl(container.resolve(TodoRepository.self))
        }

        container.register(AuthSessionUseCase.self) {
            AuthSessionUseCaseImpl(container.resolve(AuthSessionRepository.self))
        }

        container.register(FetchUserDataUseCase.self) {
            FetchUserDataUseCaseImpl(container.resolve(UserDataRepository.self))
        }

        container.register(FetchPushSettingsUseCase.self) {
            FetchPushNotificationSettingsUseCaseImpl(container.resolve(PushNotificationRepository.self))
        }

        container.register(UpsertStatusMessageUseCase.self) {
            UpsertStatusMessageUseCaseImpl(container.resolve(UserDataRepository.self))
        }

        container.register(UpdatePushSettingsUseCase.self) {
            UpdatePushSettingsUseCaseImpl(container.resolve(PushNotificationRepository.self))
        }

        container.register(FetchTodosByKindUseCase.self) {
            FetchTodosByKindUseCaseImpl(container.resolve(TodoRepository.self))
        }

        container.register(FetchWebPagesUseCase.self) {
            FetchWebPagesUseCaseImpl(container.resolve(WebPageRepository.self))
        }

        container.register(AddWebPageUseCase.self) {
            AddWebPageUseCaseImpl(container.resolve(WebPageRepository.self))
        }

        container.register(DeleteWebPageUseCase.self) {
            DeleteWebPageUseCaseImpl(container.resolve(WebPageRepository.self))
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
}
