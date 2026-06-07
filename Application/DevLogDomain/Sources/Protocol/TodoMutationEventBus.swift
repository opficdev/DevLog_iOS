//
//  TodoMutationEventBus.swift
//  DevLogDomain
//
//  Created by opfic on 6/6/26.
//

public protocol TodoMutationEventBus: Sendable {
    func publish(_ event: TodoMutationEvent) async
    func events() async -> AsyncStream<TodoMutationEvent>
}
