//
//  FCMTokenSyncHandlerTests.swift
//  AppTests
//
//  Created by opfic on 6/13/26.
//

import Foundation
import Testing
import Data
@testable import App

struct FCMTokenSyncHandlerTests {
    @Test("현재 FCM token 동기화 요청 시 token이 있으면 저장한다")
    func 현재_FCM_token_동기화_요청_시_token이_있으면_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let registrationObserver = FCMTokenNotificationObserver(
            notificationCenter: notificationCenter,
            name: .didRequestRemoteNotificationRegistration
        )
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)

        try await waitUntilFCMTokenSync {
            await userService.updatedFCMTokens == ["current-token"]
        }
        #expect(registrationObserver.didReceiveNotification)
        _ = handler
    }

    @Test("foreground 복귀 시 알림 권한이 있으면 APNs 등록을 요청하고 FCM token은 직접 저장하지 않는다")
    func foreground_복귀_시_알림_권한이_있으면_APNs_등록을_요청하고_FCM_token은_직접_저장하지_않는다() async throws {
        let notificationCenter = NotificationCenter()
        let registrationObserver = FCMTokenNotificationObserver(
            notificationCenter: notificationCenter,
            name: .didRequestRemoteNotificationRegistration
        )
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestAPNsRegistration, object: nil)

        try await waitUntilFCMTokenSync {
            registrationObserver.didReceiveNotification
        }
        try await Task.sleep(for: .milliseconds(100))
        #expect(await userService.updatedFCMTokens.isEmpty)
        _ = handler
    }

    @Test("현재 FCM token 동기화 요청 시 token이 없으면 저장하지 않는다")
    func 현재_FCM_token_동기화_요청_시_token이_없으면_저장하지_않는다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: nil)
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy()
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
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: nil)
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy()
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

        try await waitUntilFCMTokenSync {
            await userService.updatedFCMTokens == ["refreshed-token"]
        }
        _ = handler
    }

    @Test("APNs token 이벤트 수신 시 APNs token을 적용하고 현재 FCM token을 저장한다")
    func APNs_token_이벤트_수신_시_APNs_token을_적용하고_현재_FCM_token을_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy()
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

        try await waitUntilFCMTokenSync {
            await userService.updatedFCMTokens == ["current-token"]
        }
        #expect(messagingService.apnsTokens == [deviceToken])
        _ = handler
    }

    @Test("같은 사용자와 같은 FCM token은 한 번만 저장한다")
    func 같은_사용자와_같은_FCM_token은_한_번만_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntilFCMTokenSync {
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
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy(uid: "first-user")
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntilFCMTokenSync {
            await userService.updatedFCMTokens == ["current-token"]
        }

        authService.uid = "second-user"
        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntilFCMTokenSync {
            await userService.updatedFCMTokens == ["current-token", "current-token"]
        }
        _ = handler
    }

    @Test("FCM token이 바뀌면 같은 사용자도 다시 저장한다")
    func FCM_token이_바뀌면_같은_사용자도_다시_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "first-token")
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntilFCMTokenSync { await userService.updatedFCMTokens == ["first-token"] }

        messagingService.currentFCMToken = "second-token"
        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntilFCMTokenSync { await userService.updatedFCMTokens == ["first-token", "second-token"] }
        _ = handler
    }

    @Test("로그아웃 후 같은 사용자로 다시 로그인하면 같은 FCM token도 다시 저장한다")
    func 로그아웃_후_같은_사용자로_다시_로그인하면_같은_FCM_token도_다시_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy(uid: "user-id")
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntilFCMTokenSync { await userService.updatedFCMTokens == ["current-token"] }

        authService.updateSession(uid: nil)
        authService.updateSession(uid: "user-id")
        try await waitUntilFCMTokenSync { await userService.updatedFCMTokens == ["current-token", "current-token"] }
        _ = handler
    }

    @Test("FCM token 저장에 실패하면 같은 요청을 다시 저장한다")
    func FCM_token_저장에_실패하면_같은_요청을_다시_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = FCMTokenUserServiceSpy(updateError: FCMTokenSyncTestError())
        let authService = FCMTokenAuthServiceSpy()
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntilFCMTokenSync { await userService.updatedFCMTokens == ["current-token"] }

        await userService.setUpdateError(nil)
        notificationCenter.post(name: .didRequestFCMTokenSync, object: nil)
        try await waitUntilFCMTokenSync { await userService.updatedFCMTokens == ["current-token", "current-token"] }
        _ = handler
    }

    @Test("로그인 세션 전이 시 현재 FCM token을 저장한다")
    func 로그인_세션_전이_시_현재_FCM_token을_저장한다() async throws {
        let notificationCenter = NotificationCenter()
        let messagingService = FCMTokenPushMessagingServiceSpy(currentFCMToken: "current-token")
        let userService = FCMTokenUserServiceSpy()
        let authService = FCMTokenAuthServiceSpy(uid: nil)
        let handler = FCMTokenSyncHandler(
            authService: authService,
            messagingService: messagingService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        authService.updateSession(uid: "user-id")

        try await waitUntilFCMTokenSync {
            await userService.updatedFCMTokens == ["current-token"]
        }
        _ = handler
    }

}
