//
//  PushNotificationService.swift
//  DevLogData
//
//  Created by opfic on 5/14/26.
//

import Combine
import Foundation
import DevLogDomain

public protocol PushNotificationService {
    func fetchPushNotificationEnabled() async throws -> Bool
    func fetchPushNotificationTime() async throws -> DateComponents
    func updatePushNotificationSettings(isEnabled: Bool, components: DateComponents) async throws
    func requestNotifications(
        _ notificationQuery: PushNotificationQuery,
        cursor: PushNotificationCursorDTO?
    ) async throws -> PushNotificationPageResponse
    func observeNotifications(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPageResponse, Error>
    func observeUnreadPushCount() throws -> AnyPublisher<Int, Error>
    func deleteNotification(_ notificationID: String) async throws
    func undoDeleteNotification(_ notificationID: String) async throws
    func toggleNotificationRead(_ todoId: String) async throws
}
