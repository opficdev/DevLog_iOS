//
//  UserTimeZoneSyncHandler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import Combine
import Core
import Data
import Foundation

final class UserTimeZoneSyncHandler {
    private struct SyncKey: Hashable {
        let uid: String
        let timeZoneIdentifier: String
    }

    private let authService: AuthService
    private let userService: UserService
    private let logger = Logger(category: "UserTimeZoneSyncHandler")
    private var lastSyncedKey: SyncKey?
    private var syncingKeys = Set<SyncKey>()
    private var cancellables = Set<AnyCancellable>()

    init(
        authService: AuthService,
        userService: UserService,
        notificationCenter: NotificationCenter = .default
    ) {
        self.authService = authService
        self.userService = userService

        authService.observeSignedIn()
            .removeDuplicates()
            .sink { [weak self] isSignedIn in
                self?.handleSessionUpdate(isSignedIn: isSignedIn)
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .didRequestUserTimeZoneSync)
            .sink { [weak self] _ in
                self?.requestUserTimeZoneSync()
            }
            .store(in: &cancellables)
    }
}

private extension UserTimeZoneSyncHandler {
    func handleSessionUpdate(isSignedIn: Bool) {
        guard isSignedIn else {
            lastSyncedKey = nil
            syncingKeys.removeAll()
            return
        }

        requestUserTimeZoneSync()
    }

    func requestUserTimeZoneSync() {
        Task { [weak self] in
            await self?.syncUserTimeZoneIfNeeded()
        }
    }

    func syncUserTimeZoneIfNeeded() async {
        guard let uid = authService.uid else {
            logger.info("Skipping timeZone update because no authenticated user exists")
            return
        }

        let key = SyncKey(
            uid: uid,
            timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier
        )

        guard lastSyncedKey != key else {
            logger.info("Skipping timeZone update because the current user timeZone is already synced")
            return
        }
        guard !syncingKeys.contains(key) else {
            logger.info("Skipping timeZone update because the current user timeZone is already syncing")
            return
        }

        do {
            syncingKeys.insert(key)
            defer { syncingKeys.remove(key) }
            try await userService.updateUserTimeZone()
            lastSyncedKey = key
        } catch {
            logger.error("Failed to sync user timeZone", error: error)
        }
    }
}
