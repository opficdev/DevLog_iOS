//
//  WidgetSyncEventBusImpl.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Combine
import DevLogDomain
import DevLogData
import DevLogWidgetShared

final class WidgetSyncEventBusImpl: WidgetSyncEventBus {
    private let subject = PassthroughSubject<WidgetSyncEvent, Never>()

    func publish(_ event: WidgetSyncEvent) {
        subject.send(event)
    }

    func observe() -> AnyPublisher<WidgetSyncEvent, Never> {
        subject.eraseToAnyPublisher()
    }
}
