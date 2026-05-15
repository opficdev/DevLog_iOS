//
//  UserTimeZoneSyncHandler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import Combine
import DevLogData
import UIKit

final class UserTimeZoneSyncHandler {
    private let userService: UserService
    private let logger = Logger(category: "UserTimeZoneSyncHandler")
    private var cancellables = Set<AnyCancellable>()

    init(
        userService: UserService,
        notificationCenter: NotificationCenter = .default
    ) {
        self.userService = userService

        notificationCenter.publisher(for: .didRequestUserTimeZoneSync)
            .merge(with: notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification))
            .sink { [weak self] _ in
                Task {
                    do {
                        try await self?.userService.updateUserTimeZone()
                    } catch {
                        self?.logger.error("Failed to sync user timeZone", error: error)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
