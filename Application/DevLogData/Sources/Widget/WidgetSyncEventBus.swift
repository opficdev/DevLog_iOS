//
//  WidgetSyncEventBus.swift
//  DevLogData
//
//  Created by opfic on 4/30/26.
//

import Combine

public protocol WidgetSyncEventBus {
    func publish(_ event: WidgetSyncEvent)
    func observe() -> AnyPublisher<WidgetSyncEvent, Never>
}
