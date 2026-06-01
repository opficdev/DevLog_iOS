//
//  WidgetSessionSyncHandler.swift
//  DevLog
//
//  Created by opfic on 6/1/26.
//

import Combine
import Foundation
import DevLogData

final class WidgetSessionSyncHandler {
    private let authService: AuthService
    private let widgetSyncEventBus: WidgetSyncEventBus
    private var hasRequestedWidgetSync = false
    private var cancellables = Set<AnyCancellable>()

    init(
        authService: AuthService,
        widgetSyncEventBus: WidgetSyncEventBus
    ) {
        self.authService = authService
        self.widgetSyncEventBus = widgetSyncEventBus

        authService.observeSignedIn()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSignedIn in
                self?.handleSessionUpdate(isSignedIn: isSignedIn)
            }
            .store(in: &cancellables)
    }
}

private extension WidgetSessionSyncHandler {
    func handleSessionUpdate(isSignedIn: Bool) {
        guard isSignedIn else {
            hasRequestedWidgetSync = false
            return
        }

        guard hasRequestedWidgetSync == false else {
            return
        }

        hasRequestedWidgetSync = true
        widgetSyncEventBus.publish(.syncRequested)
    }
}
