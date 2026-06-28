//
//  WidgetSyncEventBusImpl.swift
//  DevLogWidget
//
//  Created by opfic on 4/30/26.
//

import Combine
import Foundation
import DevLogData

public final class WidgetSyncEventBusImpl: WidgetSyncEventBus {
    private let subject = PassthroughSubject<WidgetSyncEvent, Never>()
    private let lock = NSLock()
    private var isRequested = false

    public init() { }

    public func publish(_ event: WidgetSyncEvent) {
        subject.send(event)
    }

    public func request() {
        lock.lock()
        defer { lock.unlock() }
        isRequested = true
    }

    public func confirmRequest() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard isRequested else { return false }
        isRequested = false
        return true
    }

    public func observe() -> AnyPublisher<WidgetSyncEvent, Never> {
        subject.eraseToAnyPublisher()
    }
}
