//
//  WidgetSyncEventBusTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/30/26.
//

import Combine
import Testing
@testable import DevLog

struct WidgetSyncEventBusTests {
    @Test("WidgetSyncEventBus는 발행된 이벤트를 관찰자에게 전달한다")
    func widgetSyncEventBus는_발행된_이벤트를_관찰자에게_전달한다() {
        let bus = WidgetSyncEventBusImpl()
        var receivedEvents = [WidgetSyncEvent]()
        let cancellable = bus.observe()
            .sink { event in
                receivedEvents.append(event)
            }

        bus.publish(.todoDataChanged)
        bus.publish(.todayDisplayOptionsChanged)

        #expect(receivedEvents == [
            .todoDataChanged,
            .todayDisplayOptionsChanged
        ])
        _ = cancellable
    }
}
