//
//  FCMTokenSyncHandler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import Combine
import Foundation

final class FCMTokenSyncHandler {
    private let userService: UserService
    private let logger = Logger(category: "FCMTokenSyncHandler")
    private var cancellables = Set<AnyCancellable>()

    init(
        userService: UserService,
        notificationCenter: NotificationCenter = .default
    ) {
        self.userService = userService

        notificationCenter.publisher(for: .didRefreshFCMToken)
            .compactMap { $0.userInfo?["fcmToken"] as? String }
            .sink { [weak self] fcmToken in
                Task {
                    do {
                        try await self?.userService.updateFCMToken(fcmToken)
                    } catch {
                        self?.logger.error("Failed to sync refreshed FCM token", error: error)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
