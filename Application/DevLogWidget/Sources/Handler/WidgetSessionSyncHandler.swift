//
//  WidgetSessionSyncHandler.swift
//  DevLogWidget
//
//  Created by opfic on 6/1/26.
//

import Combine
import Foundation
import DevLogData

public final class WidgetSessionSyncHandler {
    private let provider: AuthSessionStateProvider
    private let widgetSyncEventBus: WidgetSyncEventBus
    private var hasRequestedWidgetSync = false
    private var cancellables = Set<AnyCancellable>()

    public init(
        provider: AuthSessionStateProvider,
        widgetSyncEventBus: WidgetSyncEventBus
    ) {
        self.provider = provider
        self.widgetSyncEventBus = widgetSyncEventBus

        provider.observeSignedIn()
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
