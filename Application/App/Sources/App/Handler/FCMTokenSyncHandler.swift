//
//  FCMTokenSyncHandler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import Combine
import Core
import Data
import Foundation

final class FCMTokenSyncHandler {
    private let authService: AuthService
    private let messagingService: PushMessagingService
    private let userService: UserService
    private let notificationCenter: NotificationCenter
    private let logger = Logger(category: "FCMTokenSyncHandler")
    private var cancellables = Set<AnyCancellable>()

    init(
        authService: AuthService,
        messagingService: PushMessagingService,
        userService: UserService,
        notificationCenter: NotificationCenter = .default
    ) {
        self.authService = authService
        self.messagingService = messagingService
        self.userService = userService
        self.notificationCenter = notificationCenter

        authService.observeSignedIn()
            .removeDuplicates()
            .sink { [weak self] isSignedIn in
                self?.handleSessionUpdate(isSignedIn: isSignedIn)
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .didRefreshFCMToken)
            .compactMap { $0.userInfo?["fcmToken"] as? String }
            .sink { [weak self] fcmToken in
                self?.syncFCMToken(fcmToken)
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .didRequestFCMTokenSync)
            .sink { [weak self] _ in
                self?.requestFCMTokenSync()
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .didReceiveAPNSToken)
            .compactMap { $0.userInfo?["deviceToken"] as? Data }
            .sink { [weak self] deviceToken in
                self?.handleAPNSToken(deviceToken)
            }
            .store(in: &cancellables)
    }
}

private extension FCMTokenSyncHandler {
    func handleSessionUpdate(isSignedIn: Bool) {
        guard isSignedIn else { return }

        requestFCMTokenSync()
    }

    func requestFCMTokenSync() {
        Task { [weak self] in
            guard let self else { return }
            guard await messagingService.isNotificationAuthorized() else { return }
            notificationCenter.post(name: .didRequestRemoteNotificationRegistration, object: nil)
            await syncCurrentFCMToken()
        }
    }

    func handleAPNSToken(_ deviceToken: Data) {
        messagingService.setAPNSToken(deviceToken)
        Task { [weak self] in
            await self?.syncCurrentFCMToken()
        }
    }

    func syncCurrentFCMToken() async {
        do {
            guard let fcmToken = try await messagingService.fetchFCMToken() else { return }
            try await syncFCMTokenIfNeeded(fcmToken)
        } catch {
            logger.error("Failed to sync current FCM token", error: error)
        }
    }

    func syncFCMToken(_ fcmToken: String) {
        Task { [weak self] in
            do {
                try await self?.syncFCMTokenIfNeeded(fcmToken)
            } catch {
                self?.logger.error("Failed to sync refreshed FCM token", error: error)
            }
        }
    }

    func syncFCMTokenIfNeeded(_ fcmToken: String) async throws {
        guard authService.uid != nil else {
            logger.info("Skipping FCM token update because no authenticated user exists")
            return
        }

        try await userService.updateFCMToken(fcmToken)
    }
}
