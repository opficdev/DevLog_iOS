//
//  DeletePushNotificationIntegrationTests.swift
//  DevLogAppTests
//
//  Created by opfic on 4/6/26.
//

import Testing
import Foundation

@Suite(.serialized)
struct DeletePushNotificationIntegrationTests {
    @Test("푸시 알림 삭제를 되돌리면 목록에 보인다")
    func 푸시_알림_삭제를_되돌리면_목록에_보인다() async throws {
        let authSession = try await LocalFirebaseRESTSupport.shared.anonymousSignIn()
        let notificationId = try await LocalFirebaseRESTSupport.shared.seedPushNotification(
            userId: authSession.userId
        )

        try await LocalFirebaseRESTSupport.shared.requestPushNotificationDeletion(
            notificationId: notificationId,
            idToken: authSession.idToken
        )

        try await LocalFirebaseRESTSupport.shared.waitUntil {
            let visibleNotificationIds = try await LocalFirebaseRESTSupport.shared.fetchPushNotificationIDs(
                userId: authSession.userId
            )
            return !visibleNotificationIds.contains(notificationId)
        }

        try await LocalFirebaseRESTSupport.shared.undoPushNotificationDeletion(
            notificationId: notificationId,
            idToken: authSession.idToken
        )

        try await LocalFirebaseRESTSupport.shared.waitUntil {
            let visibleNotificationIds = try await LocalFirebaseRESTSupport.shared.fetchPushNotificationIDs(
                userId: authSession.userId
            )
            return visibleNotificationIds.contains(notificationId)
        }

        try await Task.sleep(for: .seconds(6))

        let visibleNotificationIds = try await LocalFirebaseRESTSupport.shared.fetchPushNotificationIDs(
            userId: authSession.userId
        )
        #expect(visibleNotificationIds.contains(notificationId))
    }
}
