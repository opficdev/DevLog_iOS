//
//  WidgetSyncEventBus.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Combine

protocol WidgetSyncEventBus {
    func publish(_ event: WidgetSyncEvent)
    func observe() -> AnyPublisher<WidgetSyncEvent, Never>
}
