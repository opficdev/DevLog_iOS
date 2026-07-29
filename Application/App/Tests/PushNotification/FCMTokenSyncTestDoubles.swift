//
//  FCMTokenSyncTestDoubles.swift
//  AppTests
//
//  Created by opfic on 7/20/26.
//

import Combine
import Data
import Foundation
import Testing

actor FCMTokenUserServiceSpy: UserService {
    private(set) var updatedFCMTokenValues = [FCMTokenUpdate]()
    private var updateError: Error?

    var updatedFCMTokens: [String] {
        updatedFCMTokenValues.map(\.fcmToken)
    }

    init(updateError: Error? = nil) {
        self.updateError = updateError
    }

    func upsertUser(_ response: AuthDataResponse) async throws { }
    func fetchUserProfile() async throws -> UserProfileResponse { fatalError() }
    func upsertStatusMessage(_ message: String) async throws { }

    func updateFCMToken(_ update: FCMTokenUpdate) async throws {
        updatedFCMTokenValues.append(update)
        if let updateError {
            throw updateError
        }
    }

    func updateUserTimeZone() async throws { }

    func setUpdateError(_ error: Error?) {
        updateError = error
    }
}

final class FCMTokenAuthServiceSpy: AuthService {
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

final class FCMTokenPushMessagingServiceSpy: PushMessagingService {
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

struct FCMTokenSyncTestError: Error { }

final class FCMTokenNotificationObserver {
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

func waitUntilFCMTokenSync(
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
