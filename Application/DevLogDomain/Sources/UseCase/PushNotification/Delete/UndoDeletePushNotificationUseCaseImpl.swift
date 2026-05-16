//
//  UndoDeletePushNotificationUseCaseImpl.swift
//  DevLogDomain
//
//  Created by opfic on 3/16/26.
//

public final class UndoDeletePushNotificationUseCaseImpl: UndoDeletePushNotificationUseCase {
    private let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    public func execute(_ notificationID: String) async throws {
        try await repository.undoDeleteNotification(notificationID)
    }
}
