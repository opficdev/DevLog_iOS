//
//  FetchPushNotificationsUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

protocol FetchPushNotificationsUseCase {
    func execute(_ query: PushNotificationQuery) async throws -> [PushNotification]
}
