//
//  FCMTokenSyncHandler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import Combine
import DevLogCore
import DevLogData
import Foundation

final class FCMTokenSyncHandler {
    private let messagingService: PushMessagingService
    private let userService: UserService
    private let notificationCenter: NotificationCenter
    private let logger = Logger(category: "FCMTokenSyncHandler")
    private var cancellables = Set<AnyCancellable>()

    init(
        messagingService: PushMessagingService,
        userService: UserService,
        notificationCenter: NotificationCenter = .default
    ) {
        self.messagingService = messagingService
        self.userService = userService
        self.notificationCenter = notificationCenter

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
    func requestFCMTokenSync() {
        Task { [weak self] in
            guard let self else { return }
            guard await messagingService.isNotificationAuthorized() else {
                return
            }
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
            guard let fcmToken = try await messagingService.fetchFCMToken() else {
                return
            }
            try await userService.updateFCMToken(fcmToken)
        } catch {
            logger.error("Failed to sync current FCM token", error: error)
        }
    }

    func syncFCMToken(_ fcmToken: String) {
        Task { [weak self] in
            do {
                try await self?.userService.updateFCMToken(fcmToken)
            } catch {
                self?.logger.error("Failed to sync refreshed FCM token", error: error)
            }
        }
    }
}
