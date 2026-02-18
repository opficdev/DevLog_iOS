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
    func requestNotifications(_ query: PushNotificationQuery) async throws -> [PushNotification] {
        try await service.requestNotifications(query)
            .compactMap { dto in
                guard
                    let id = dto.id,
                    let todoKind = TodoKind(rawValue: dto.todoKind)
                else { return nil }

                return PushNotification(
                    id: id,
                    title: dto.title,
                    body: dto.body,
                    receivedAt: dto.receivedAt.dateValue(),
                    isRead: dto.isRead,
                    todoID: dto.todoID,
                    todoKind: todoKind
                )
            }
    }

    // 푸시 알림 기록 삭제
    func deleteNotification(_ notificationID: String) async throws {
        try await service.deleteNotification(notificationID)
    }

    // 푸시 알림 읽음/안읽음 토글
    func toggleNotificationRead(_ todoID: String) async throws {
        try await service.toggleNotificationRead(todoID)
    }
}
