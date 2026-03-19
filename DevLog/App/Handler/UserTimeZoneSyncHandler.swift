//
//  UserTimeZoneSyncHandler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import Combine
import Foundation

final class UserTimeZoneSyncHandler {
    private let repository: UserDataRepository
    private let logger = Logger(category: "UserTimeZoneSyncHandler")
    private var cancellables = Set<AnyCancellable>()

    init(
        repository: UserDataRepository,
        notificationCenter: NotificationCenter = .default
    ) {
        self.repository = repository

        notificationCenter.publisher(for: .didRequestUserTimeZoneSync)
            .sink { [weak self] _ in
                Task {
                    do {
                        try await self?.repository.updateUserTimeZone()
                    } catch {
                        self?.logger.error("Failed to sync user timeZone", error: error)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
