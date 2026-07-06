//
//  TestSupport.swift
//  PresentationSharedTests
//
//  Created by opfic on 4/6/26.
//

import Testing
import Foundation
import Core
import Domain
@testable import PresentationShared

@MainActor
func waitUntil(
    timeout: Duration = .seconds(1),
    pollInterval: Duration = .milliseconds(20),
    _ condition: @escaping () -> Bool
) async {
    let continuousClock = ContinuousClock()
    let deadline = continuousClock.now + timeout

    while !condition() && continuousClock.now < deadline {
        try? await Task.sleep(for: pollInterval)
    }
}

final class UpsertTodoUseCaseSpy: UpsertTodoUseCase {
    private(set) var todos: [Todo] = []
    private(set) var todoDrafts: [TodoDraft] = []

    func execute(_ todo: Todo) async throws {
        todos.append(todo)
    }

    func execute(_ todoDraft: TodoDraft) async throws {
        todoDrafts.append(todoDraft)
    }
}
