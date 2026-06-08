//
//  TodoMutationEventBus.swift
//  DevLogDomain
//
//  Created by opfic on 6/6/26.
//

import Combine

public protocol TodoMutationEventBus {
    func publish(_ event: TodoMutationEvent)
    func observe() -> AnyPublisher<TodoMutationEvent, Never>
}
