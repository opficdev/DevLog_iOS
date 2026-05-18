//
//  WidgetSyncEventBusImpl.swift
//  DevLogWidgetCore
//
//  Created by opfic on 4/30/26.
//

import Combine

public final class WidgetSyncEventBusImpl: WidgetSyncEventBus {
    private let subject = PassthroughSubject<WidgetSyncEvent, Never>()

    public init() { }

    public func publish(_ event: WidgetSyncEvent) {
        subject.send(event)
    }

    public func observe() -> AnyPublisher<WidgetSyncEvent, Never> {
        subject.eraseToAnyPublisher()
    }
}
