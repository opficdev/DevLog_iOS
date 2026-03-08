//
//  FetchPushNotificationsUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

import Combine

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

    func observe(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPage, Error> {
        try repository.observeNotifications(query, limit: limit)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
