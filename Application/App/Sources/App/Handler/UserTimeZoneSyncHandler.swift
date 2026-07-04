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

    private enum SyncStartResult {
        case started
        case alreadySynced
        case alreadySyncing
    }

    private let authService: AuthService
    private let userService: UserService
    private let logger = Logger(category: "UserTimeZoneSyncHandler")
    private let lock = NSLock()
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
            resetSyncState()
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

        switch beginSync(for: key) {
        case .started:
            break
        case .alreadySynced:
            logger.info("Skipping timeZone update because the current user timeZone is already synced")
            return
        case .alreadySyncing:
            logger.info("Skipping timeZone update because the current user timeZone is already syncing")
            return
        }

        do {
            try await userService.updateUserTimeZone()
            finishSync(for: key, didSucceed: true)
        } catch {
            finishSync(for: key, didSucceed: false)
            logger.error("Failed to sync user timeZone", error: error)
        }
    }

    private func resetSyncState() {
        lock.lock()
        defer { lock.unlock() }

        lastSyncedKey = nil
        syncingKeys.removeAll()
    }

    private func beginSync(for key: SyncKey) -> SyncStartResult {
        lock.lock()
        defer { lock.unlock() }

        if lastSyncedKey == key {
            return .alreadySynced
        }
        if syncingKeys.contains(key) {
            return .alreadySyncing
        }

        syncingKeys.insert(key)
        return .started
    }

    private func finishSync(for key: SyncKey, didSucceed: Bool) {
        lock.lock()
        defer { lock.unlock() }

        syncingKeys.remove(key)
        if didSucceed {
            lastSyncedKey = key
        }
    }
}
