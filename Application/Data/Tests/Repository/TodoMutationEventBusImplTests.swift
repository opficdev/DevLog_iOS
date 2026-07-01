//
//  TodoMutationEventBusImplTests.swift
//  DataTests
//
//  Created by opfic on 6/6/26.
//

import Combine
import Testing
import Domain
@testable import Data

struct TodoMutationEventBusImplTests {
    @Test("TodoMutationEventBus는 발행된 이벤트를 관찰자에게 전달한다")
    func todoMutationEventBus는_발행된_이벤트를_관찰자에게_전달한다() {
        let bus = TodoMutationEventBusImpl()
        var events = [TodoMutationEvent]()
        var cancellables = Set<AnyCancellable>()

        bus.observe()
            .sink { events.append($0) }
            .store(in: &cancellables)

        bus.publish(.updated("todo-id"))

        #expect(events == [.updated("todo-id")])
    }
}
