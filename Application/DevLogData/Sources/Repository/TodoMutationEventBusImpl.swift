//
//  TodoMutationEventBusImpl.swift
//  DevLogData
//
//  Created by opfic on 6/6/26.
//

import Foundation
import DevLogDomain

actor TodoMutationEventBusImpl: TodoMutationEventBus {
    private var continuations = [UUID: AsyncStream<TodoMutationEvent>.Continuation]()

    func publish(_ event: TodoMutationEvent) async {
        continuations.values.forEach { $0.yield(event) }
    }

    func events() -> AsyncStream<TodoMutationEvent> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: TodoMutationEvent.self)

        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeContinuation(id: id)
            }
        }

        return stream
    }
}

private extension TodoMutationEventBusImpl {
    func removeContinuation(id: UUID) {
        continuations[id] = nil
    }
}
