//
//  FetchPushNotificationsUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

import Combine

protocol FetchPushNotificationsUseCase {
    func execute(
        _ query: PushNotificationQuery,
        cursor: PushNotificationCursor?
    ) async throws -> PushNotificationPage

    func observe(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPage, Error>
}
