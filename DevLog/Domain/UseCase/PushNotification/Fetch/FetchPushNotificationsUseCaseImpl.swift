//
//  FetchPushNotificationsUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

final class FetchPushNotificationsUseCaseImpl: FetchPushNotificationsUseCase {
    private let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    func execute(
        _ query: PushNotificationQuery,
        cursor: PushNotificationCursor?
    ) async throws -> PushNotificationPage {
        try await repository.requestNotifications(query, cursor: cursor)
    }
}
