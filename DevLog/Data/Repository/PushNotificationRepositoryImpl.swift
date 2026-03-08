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

    /// 푸시 알림 On/Off 설정
    func fetchPushNotificationEnabled() async throws -> Bool {
        return try await service.fetchPushNotificationEnabled()
    }

    /// 푸시 알림 시간 설정
    func fetchPushNotificationTime() async throws -> DateComponents {
        return try await service.fetchPushNotificationTime()
    }

    /// 푸시 알림 설정 업데이트
    func updatePushNotificationSettings(_ settings: PushNotificationSettings) async throws {
        try await service.updatePushNotificationSettings(
            isEnabled: settings.isEnabled, components: settings.scheduledTime
        )
    }

    /// 푸시 알림 기록 요청
    func requestNotifications(
        _ query: PushNotificationQuery,
        cursor: PushNotificationCursor?
    ) async throws -> PushNotificationPage {
        let cursorDTO = cursor.map { PushNotificationCursorDTO.fromDomain($0) }
        let response = try await service.requestNotifications(query, cursor: cursorDTO)
        return try response.toDomain()
    }

    // 푸시 알림 기록 삭제
    func deleteNotification(_ notificationID: String) async throws {
        try await service.deleteNotification(notificationID)
    }

    // 푸시 알림 읽음/안읽음 토글
    func toggleNotificationRead(_ todoId: String) async throws {
        try await service.toggleNotificationRead(todoId)
    }
}
