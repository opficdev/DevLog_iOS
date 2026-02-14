//
//  TogglePushNotificationReadUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 2/13/26.
//

final class TogglePushNotificationReadUseCaseImpl: TogglePushNotificationReadUseCase {
    private let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    func execute(_ todoID: String) async throws {
        try await repository.toggleNotificationRead(todoID)
    }
}
