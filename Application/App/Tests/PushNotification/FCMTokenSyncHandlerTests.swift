//
//  FCMTokenSyncHandlerTests.swift
//  AppTests
//
//  Created by opfic on 6/13/26.
//

import Foundation
import Combine
import Testing
import Data
@testable import App

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
        let authService = AuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
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

    @Test("foreground 복귀 시 알림 권한이 있으면 APNs 등록을 요청하고 FCM token은 직접 저장하지 않는다")
    func foreground_복귀_시_알림_권한이_있으면_APNs_등록을_요청하고_FCM_token은_직접_저장하지_않는다() async throws {
        let notificationCenter = NotificationCenter()
        let registrationObserver = NotificationObserver(
            notificationCenter: notificationCenter,
            name: .didRequestRemoteNotificationRegistration
        )
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestAPNsRegistration, object: nil)

        try await waitUntil {
            registrationObserver.didReceiveNotification
        }
        try await Task.sleep(for: .milliseconds(100))
        #expect(await userService.updatedFCMTokens.isEmpty)
        _ = handler
    }

    @Test("현재 FCM token 동기화 요청 시 token이 없으면 저장하지 않는다")
    func 현재_FCM_token_동기화_요청_시_token이_없으면_저장하지_않는다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: nil)
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
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
        let authService = AuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
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
        let authService = AuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
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

    @Test("같은 사용자와 같은 FCM token은 한 번만 저장한다")
    func 같은_사용자와_같은_FCM_token은_한_번만_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntil {
            await userService.updatedFCMTokens == ["current-token"]
        }

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await Task.sleep(for: .milliseconds(100))
        #expect(await userService.updatedFCMTokens == ["current-token"])

        _ = handler
    }

    @Test("같은 FCM token이어도 사용자가 바뀌면 다시 저장한다")
    func 같은_FCM_token이어도_사용자가_바뀌면_다시_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy(uid: "first-user")
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntil {
            await userService.updatedFCMTokens == ["current-token"]
        }

        authService.uid = "second-user"
        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntil {
            await userService.updatedFCMTokens == ["current-token", "current-token"]
        }
        _ = handler
    }

    @Test("FCM token이 바뀌면 같은 사용자도 다시 저장한다")
    func FCM_token이_바뀌면_같은_사용자도_다시_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "first-token")
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntil { await userService.updatedFCMTokens == ["first-token"] }

        messagingService.currentFCMToken = "second-token"
        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntil { await userService.updatedFCMTokens == ["first-token", "second-token"] }
        _ = handler
    }

    @Test("로그아웃 후 같은 사용자로 다시 로그인하면 같은 FCM token도 다시 저장한다")
    func 로그아웃_후_같은_사용자로_다시_로그인하면_같은_FCM_token도_다시_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy(uid: "user-id")
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntil { await userService.updatedFCMTokens == ["current-token"] }

        authService.updateSession(uid: nil)
        authService.updateSession(uid: "user-id")
        try await waitUntil { await userService.updatedFCMTokens == ["current-token", "current-token"] }
        _ = handler
    }

    @Test("FCM token 저장에 실패하면 같은 요청을 다시 저장한다")
    func FCM_token_저장에_실패하면_같은_요청을_다시_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = UserServiceSpy(updateError: FCMTokenSyncTestError())
        let authService = AuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntil { await userService.updatedFCMTokens == ["current-token"] }

        await userService.setUpdateError(nil)
        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntil { await userService.updatedFCMTokens == ["current-token", "current-token"] }
        _ = handler
    }

    @Test("로그인 세션 전이 시 현재 FCM token을 저장한다")
    func 로그인_세션_전이_시_현재_FCM_token을_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = PushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy(uid: nil)
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        authService.updateSession(uid: "user-id")

        try await waitUntil {
            await userService.updatedFCMTokens == ["current-token"]
        }
        _ = handler
    }

}

private actor UserServiceSpy: UserService {
    private(set) var updatedFCMTokens = [String]()
    private var updateError: Error?

    init(updateError: Error? = nil) {
        self.updateError = updateError
    }

    func upsertUser(_ response: AuthDataResponse) async throws { }
    func fetchUserProfile() async throws -> UserProfileResponse { fatalError() }
    func upsertStatusMessage(_ message: String) async throws { }

    func updateFCMToken(_ fcmToken: String) async throws {
        updatedFCMTokens.append(fcmToken)
        if let updateError {
            throw updateError
        }
    }

    func updateUserTimeZone() async throws { }

    func setUpdateError(_ error: Error?) {
        updateError = error
    }
}

private final class AuthServiceSpy: AuthService {
    var uid: String?
    let providerIDs = [String]()
    let providerCount = 0
    private let subject = PassthroughSubject<Bool, Never>()

    init(uid: String? = "user-id") {
        self.uid = uid
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func updateSession(uid: String?) {
        self.uid = uid
        subject.send(uid != nil)
    }

    func beginSignIn() { }
    func completeSignIn() { }
    func cancelSignIn() { }
    func getProviderID() async throws -> String? { nil }
    func deleteCurrentUser() async throws { }
    func clearCurrentSession() async throws { }
}

private final class PushMessagingServiceSpy: PushMessagingService {
    var currentFCMToken: String?
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

private struct FCMTokenSyncTestError: Error { }

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
