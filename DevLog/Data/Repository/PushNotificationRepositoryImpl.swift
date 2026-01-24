//
//  PushNotificationRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 1/18/26.
//

import Foundation

final class PushNotificationRepositoryImpl: PushNotificationRepository {
    private let service: PushNotificationService

    init(_ service: PushNotificationService) {
        self.service = service
    }

    func fetchPushNotificationTime() async throws -> DateComponents {
        return try await service.fetchPushNotificationTime()
    }
    
    func updatePushNotificationEnabled(_ enabled: Bool) async throws {
        try await service.updatePushNotificationEnabled(enabled)
    }

    func fetchPushNotificationEnabled() async throws -> Bool {
        return try await service.fetchPushNotificationEnabled()
    }

    func updatePushNotificationTime(_ date: Date) async throws {
        try await service.updatePushNotificationTime(date)
    }
}
