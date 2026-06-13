//
//  FCMTokenSyncHandlerTests.swift
//  DevLogAppTests
//
//  Created by opfic on 6/13/26.
//

import Foundation
import Testing
import DevLogData
@testable import DevLogApp

struct FCMTokenSyncHandlerTests {
    @Test("현재 FCM token 동기화 요청 시 token이 있으면 저장한다")
    func 현재_FCM_token_동기화_요청_시_token이_있으면_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let registrationObserver = NotificationObserver(
            notificationCenter: notificationCenter,
            name: .didRequestRemoteNotificationRegistration
        )
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = UserServiceSpy()
        let handler = FCMTokenSyncHandler(
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)

        try await waitUntil {
            await userService.updatedFCMTokens == ["current-token"]
        }
        #expect(registrationObserver.didReceiveNotification)
        _ = handler
    }

    @Test("현재 FCM token 동기화 요청 시 token이 없으면 저장하지 않는다")
    func 현재_FCM_token_동기화_요청_시_token이_없으면_저장하지_않는다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: nil)
        let userService = UserServiceSpy()
        let handler = FCMTokenSyncHandler(
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)

        try await Task.sleep(for: .milliseconds(100))
        #expect(await userService.updatedFCMTokens.isEmpty)
        _ = handler
    }

    @Test("갱신된 FCM token 이벤트 수신 시 저장한다")
    func 갱신된_FCM_token_이벤트_수신_시_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: nil)
        let userService = UserServiceSpy()
        let handler = FCMTokenSyncHandler(
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(
            name: .didRefreshFCMToken,
            object: nil,
            userInfo: ["fcmToken": "refreshed-token"]
        )

        try await waitUntil {
            await userService.updatedFCMTokens == ["refreshed-token"]
        }
        _ = handler
    }

    @Test("APNs token 이벤트 수신 시 APNs token을 적용하고 현재 FCM token을 저장한다")
    func APNs_token_이벤트_수신_시_APNs_token을_적용하고_현재_FCM_token을_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = UserServiceSpy()
        let handler = FCMTokenSyncHandler(
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )
        let deviceToken = Data([0x01, 0x02, 0x03])

        notificationCenter.post(
            name: .didReceiveAPNSToken,
            object: nil,
            userInfo: ["deviceToken": deviceToken]
        )

        try await waitUntil {
            await userService.updatedFCMTokens == ["current-token"]
        }
        #expect(messagingService.apnsTokens == [deviceToken])
        _ = handler
    }
}

private actor UserServiceSpy: UserService {
    private(set) var updatedFCMTokens = [String]()

    func upsertUser(_ response: AuthDataResponse) async throws { }
    func fetchUserProfile() async throws -> UserProfileResponse { fatalError() }
    func upsertStatusMessage(_ message: String) async throws { }

    func updateFCMToken(_ fcmToken: String) async throws {
        updatedFCMTokens.append(fcmToken)
    }

    func updateUserTimeZone() async throws { }
}

private final class PushMessagingServiceSpy: PushMessagingService {
    private let currentFCMToken: String?
    private(set) var apnsTokens = [Data]()

    init(currentFCMToken: String?) {
        self.currentFCMToken = currentFCMToken
    }

    func setDelegate(_ delegate: PushMessagingServiceDelegate?) { }
    func setAPNSToken(_ deviceToken: Data) {
        apnsTokens.append(deviceToken)
    }
    func isNotificationAuthorized() async -> Bool { true }

    func fetchFCMToken() async throws -> String? {
        currentFCMToken
    }
}

private final class NotificationObserver {
    private(set) var didReceiveNotification = false
    private var token: NSObjectProtocol?
    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter, name: Notification.Name) {
        self.notificationCenter = notificationCenter
        self.token = notificationCenter.addObserver(
            forName: name,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.didReceiveNotification = true
        }
    }

    deinit {
        if let token {
            notificationCenter.removeObserver(token)
        }
    }
}

private func waitUntil(
    timeout: Duration = .seconds(1),
    pollInterval: Duration = .milliseconds(10),
    condition: @escaping @Sendable () async -> Bool
) async throws {
    let deadline = ContinuousClock.now + timeout

    while ContinuousClock.now < deadline {
        if await condition() {
            return
        }
        try await Task.sleep(for: pollInterval)
    }

    Issue.record("조건을 만족하지 못함")
}
