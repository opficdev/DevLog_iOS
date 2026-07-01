//
//  TodoMutationEventBusImpl.swift
//  Data
//
//  Created by opfic on 6/6/26.
//

import Combine
import Domain

final class TodoMutationEventBusImpl: TodoMutationEventBus {
    private let subject = PassthroughSubject<TodoMutationEvent, Never>()

    func publish(_ event: TodoMutationEvent) {
        subject.send(event)
    }

    func observe() -> AnyPublisher<TodoMutationEvent, Never> {
        subject.eraseToAnyPublisher()
    }
}
