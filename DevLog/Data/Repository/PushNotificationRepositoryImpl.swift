//
//  PushNotificationRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 1/18/26.
//

import Foundation

final class PushNotificationRepositoryImpl: PushNotificationRepository {
    private let service: PushNotificationService

    init(pushNotificationService: PushNotificationService) {
        self.service = pushNotificationService
    }

    func fetchPushNotificationEnabled() async throws -> Bool {
        return try await service.fetchPushNotificationEnabled()
    }

    func fetchPushNotificationTime() async throws -> DateComponents {
        return try await service.fetchPushNotificationTime()
    }

    func updatePushNotificationSettings(_ settings: PushNotificationSettings) async throws {
        try await service.updatePushNotificationSettings(
            isEnabled: settings.isEnabled, components: settings.scheduledTime
        )
    }
}
