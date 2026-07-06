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

final class FetchUserDataUseCaseSpy: FetchUserDataUseCase {
    var profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
    }

    func execute() async throws -> UserProfile {
        profile
    }
}

final class FetchProfileImageDataUseCaseSpy: FetchProfileImageDataUseCase {
    var data: Data
    private(set) var calledURLs: [URL] = []

    init(data: Data) {
        self.data = data
    }

    func execute(from url: URL) async throws -> Data {
        calledURLs.append(url)
        return data
    }
}

final class UpsertStatusMessageUseCaseSpy: UpsertStatusMessageUseCase {
    private(set) var messages: [String] = []

    func execute(_ message: String) async throws {
        messages.append(message)
    }
}

final class FetchHeatmapActivityTypesUseCaseSpy: FetchHeatmapActivityTypesUseCase {
    var activityTypes: [String] = []

    func execute() -> [String] {
        activityTypes
    }
}

final class UpdateHeatmapActivityTypesUseCaseSpy: UpdateHeatmapActivityTypesUseCase {
    private(set) var activityTypes: [[String]] = []

    func execute(_ activityTypes: [String]) {
        self.activityTypes.append(activityTypes)
    }
}
