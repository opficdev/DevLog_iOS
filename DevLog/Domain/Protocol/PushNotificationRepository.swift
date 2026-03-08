//
//  PushNotificationRepository.swift
//  DevLog
//
//  Created by 최윤진 on 1/18/26.
//

import Foundation

protocol PushNotificationRepository {
    func fetchPushNotificationEnabled() async throws -> Bool
    func fetchPushNotificationTime() async throws -> DateComponents
    func updatePushNotificationSettings(_ settings: PushNotificationSettings) async throws
    func requestNotifications(
        _ query: PushNotificationQuery,
        cursor: PushNotificationCursor?
    ) async throws -> PushNotificationPage
    func deleteNotification(_ notificationID: String) async throws
    func toggleNotificationRead(_ todoId: String) async throws
}
