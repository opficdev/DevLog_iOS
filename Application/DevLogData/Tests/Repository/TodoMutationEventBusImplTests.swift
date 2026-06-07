//
//  TodoMutationEventBusImplTests.swift
//  DevLogDataTests
//
//  Created by opfic on 6/6/26.
//

import Testing
import DevLogDomain
@testable import DevLogData

struct TodoMutationEventBusImplTests {
    @Test("TodoMutationEventBus는 발행된 이벤트를 관찰자에게 전달한다")
    func todoMutationEventBus는_발행된_이벤트를_관찰자에게_전달한다() async {
        let bus = TodoMutationEventBusImpl()
        let events = await bus.events()
        let task = Task {
            var iterator = events.makeAsyncIterator()
            return await iterator.next()
        }

        await bus.publish(.updated("todo-id"))

        let event = await task.value
        #expect(event == .updated("todo-id"))
    }
}
