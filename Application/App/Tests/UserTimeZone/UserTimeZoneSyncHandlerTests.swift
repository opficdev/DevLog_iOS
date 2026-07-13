//
//  UserTimeZoneSyncHandlerTests.swift
//  AppTests
//
//  Created by opfic on 7/3/26.
//

import Combine
import Foundation
import Testing
import Data
@testable import App

struct UserTimeZoneSyncHandlerTests {
    @Test("로그인 세션 전이 시 현재 timeZone을 저장한다")
    func 로그인_세션_전이_시_현재_timeZone을_저장한다() async throws {
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy(uid: nil)
        let handler = UserTimeZoneSyncHandler(
            authService: authService,
            userService: userService
        )

        authService.updateSession(uid: "user-id")

        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 1
        }
        _ = handler
    }

    @Test("같은 사용자와 같은 timeZone은 중복 저장하지 않는다")
    func 같은_사용자와_같은_timeZone은_중복_저장하지_않는다() async throws {
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy(uid: "user-id")
        let handler = UserTimeZoneSyncHandler(
            authService: authService,
            userService: userService
        )

        authService.updateSession(uid: "user-id")
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 1
        }

        authService.updateSession(uid: "user-id")
        try await Task.sleep(for: .milliseconds(100))
        #expect(await userService.updateUserTimeZoneCallCount == 1)
        _ = handler
    }

    @Test("같은 로그인 상태가 연속 방출되면 현재 timeZone을 한 번만 저장한다")
    func 같은_로그인_상태가_연속_방출되면_현재_timeZone을_한_번만_저장한다() async throws {
        let userService = UserServiceSpy(updateDelay: .milliseconds(100))
        let authService = AuthServiceSpy(uid: "user-id")
        let handler = UserTimeZoneSyncHandler(
            authService: authService,
            userService: userService
        )

        authService.updateSession(uid: "user-id")
        authService.updateSession(uid: "user-id")

        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 1
        }
        try await Task.sleep(for: .milliseconds(150))
        #expect(await userService.updateUserTimeZoneCallCount == 1)
        _ = handler
    }

    @Test("foreground 복귀 시 현재 timeZone을 요청하되 같은 사용자와 같은 timeZone은 중복 저장하지 않는다")
    func foreground_복귀_시_현재_timeZone을_요청하되_같은_사용자와_같은_timeZone은_중복_저장하지_않는다() async throws {
        let notificationCenter = NotificationCenter()
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy(uid: "user-id")
        let handler = UserTimeZoneSyncHandler(
            authService: authService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        notificationCenter.post(name: .didRequestUserTimeZoneSync, object: nil)
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 1
        }

        notificationCenter.post(name: .didRequestUserTimeZoneSync, object: nil)
        try await Task.sleep(for: .milliseconds(100))
        #expect(await userService.updateUserTimeZoneCallCount == 1)
        _ = handler
    }

    @Test("현재 timeZone 저장 중 foreground 요청이 들어오면 중복 저장하지 않는다")
    func 현재_timeZone_저장_중_foreground_요청이_들어오면_중복_저장하지_않는다() async throws {
        let notificationCenter = NotificationCenter()
        let userService = UserServiceSpy(updateDelay: .milliseconds(100))
        let authService = AuthServiceSpy(uid: "user-id")
        let handler = UserTimeZoneSyncHandler(
            authService: authService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        authService.updateSession(uid: "user-id")
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 1
        }

        notificationCenter.post(name: .didRequestUserTimeZoneSync, object: nil)
        try await Task.sleep(for: .milliseconds(150))
        #expect(await userService.updateUserTimeZoneCallCount == 1)
        _ = handler
    }

    @Test("로그아웃 후 다른 사용자로 로그인하면 같은 timeZone이어도 다시 저장한다")
    func 로그아웃_후_다른_사용자로_로그인하면_같은_timeZone이어도_다시_저장한다() async throws {
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy(uid: "first-user")
        let handler = UserTimeZoneSyncHandler(
            authService: authService,
            userService: userService
        )

        authService.updateSession(uid: "first-user")
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 1
        }

        authService.updateSession(uid: nil)
        authService.updateSession(uid: "second-user")
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 2
        }
        _ = handler
    }

    @Test("로그아웃 상태에서는 timeZone을 저장하지 않고 캐시를 초기화한다")
    func 로그아웃_상태에서는_timeZone을_저장하지_않고_캐시를_초기화한다() async throws {
        let userService = UserServiceSpy()
        let authService = AuthServiceSpy(uid: "user-id")
        let handler = UserTimeZoneSyncHandler(
            authService: authService,
            userService: userService
        )

        authService.updateSession(uid: "user-id")
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 1
        }

        authService.updateSession(uid: nil)
        try await Task.sleep(for: .milliseconds(100))
        #expect(await userService.updateUserTimeZoneCallCount == 1)

        authService.updateSession(uid: "user-id")
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 2
        }
        _ = handler
    }

    @Test("timeZone 저장 실패 시 캐시를 갱신하지 않는다")
    func timeZone_저장_실패_시_캐시를_갱신하지_않는다() async throws {
        let notificationCenter = NotificationCenter()
        let userService = UserServiceSpy(updateError: TestError.updateFailed)
        let authService = AuthServiceSpy(uid: "user-id")
        let handler = UserTimeZoneSyncHandler(
            authService: authService,
            userService: userService,
            notificationCenter: notificationCenter
        )

        authService.updateSession(uid: "user-id")
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 1
        }

        await userService.setUpdateError(nil)
        notificationCenter.post(name: .didRequestUserTimeZoneSync, object: nil)
        try await waitUntil {
            await userService.updateUserTimeZoneCallCount == 2
        }
        _ = handler
    }
}

private actor UserServiceSpy: UserService {
    private var updateError: Error?
    private let updateDelay: Duration?
    private(set) var updateUserTimeZoneCallCount = 0

    init(updateError: Error? = nil, updateDelay: Duration? = nil) {
        self.updateError = updateError
        self.updateDelay = updateDelay
    }

    func upsertUser(_ response: AuthDataResponse) async throws { }
    func fetchUserProfile() async throws -> UserProfileResponse { fatalError() }
    func upsertStatusMessage(_ message: String) async throws { }
    func updateFCMToken(_ fcmToken: String) async throws { }

    func updateUserTimeZone() async throws {
        updateUserTimeZoneCallCount += 1
        if let updateDelay {
            try await Task.sleep(for: updateDelay)
        }
        if let updateError {
            throw updateError
        }
    }

    func setUpdateError(_ updateError: Error?) {
        self.updateError = updateError
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

private enum TestError: Error {
    case updateFailed
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
