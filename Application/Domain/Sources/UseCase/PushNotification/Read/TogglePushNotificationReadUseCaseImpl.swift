//
//  TogglePushNotificationReadUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 2/13/26.
//

public final class TogglePushNotificationReadUseCaseImpl: TogglePushNotificationReadUseCase {
    private let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    public func execute(_ todoId: String) async throws {
        try await repository.toggleNotificationRead(todoId)
    }
}
