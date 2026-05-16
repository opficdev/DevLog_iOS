//
//  DeletePushNotificationUseCaseImpl.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/10/26.
//

public final class DeletePushNotificationUseCaseImpl: DeletePushNotificationUseCase {
    private let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    public func execute(_ notificationID: String) async throws {
        try await repository.deleteNotification(notificationID)
    }
}
