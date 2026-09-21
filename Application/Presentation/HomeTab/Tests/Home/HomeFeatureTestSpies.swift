//
//  HomeFeatureTestSpies.swift
//  HomeTabTests
//
//  Created by opfic on 7/2/26.
//

import Combine
import Core
import Domain

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

final class FetchTodoCategoryPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCase {
    private(set) var executeCount = 0
    var todoCategoryPreferences: [TodoCategoryPreference] = []

    func execute() async throws -> [TodoCategoryPreference] {
        executeCount += 1
        return todoCategoryPreferences
    }
}

final class UpdateTodoCategoryPreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCase {
    private(set) var updates: [[TodoCategoryPreference]] = []

    func execute(_ preferences: [TodoCategoryPreference]) async throws {
        updates.append(preferences)
    }
}

final class ObserveNetworkConnectivityUseCaseSpy: ObserveNetworkConnectivityUseCase {
    let currentValueSubject = CurrentValueSubject<Bool, Never>(true)

    func observe() -> AnyPublisher<Bool, Never> {
        currentValueSubject.eraseToAnyPublisher()
    }
}

final class FetchDevelopmentGoalsUseCaseSpy: FetchDevelopmentGoalsUseCase {
    private(set) var queries = [DevelopmentGoal.Query]()
    var result: Result<[DevelopmentGoal], Error> = .success([])

    func execute(_ query: DevelopmentGoal.Query) async throws -> [DevelopmentGoal] {
        queries.append(query)
        return try result.get()
    }
}

final class FetchDevelopmentRecordsUseCaseSpy: FetchDevelopmentRecordsUseCase {
    var resultByGoalID = [String: Result<[DevelopmentRecord], Error>]()

    func execute(goalId: String) async throws -> [DevelopmentRecord] {
        try resultByGoalID[goalId, default: .success([])].get()
    }
}

final class FetchDevelopmentRecordVersionUseCaseSpy: FetchDevelopmentRecordVersionUseCase {
    var resultByRecordID = [String: Result<DevelopmentRecord.Version, Error>]()

    func execute(
        goalId: String,
        recordId: String,
        versionId: String
    ) async throws -> DevelopmentRecord.Version {
        try resultByRecordID[recordId, default: .failure(DevelopmentGoalTestError.notFound)].get()
    }
}

final class FetchTodosUseCaseSpy: FetchTodosUseCase {
    private(set) var queries = [TodoQuery]()
    var page = TodoPage(items: [], nextCursor: nil)

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)
        return page
    }
}

enum DevelopmentGoalTestError: Error {
    case failed
    case notFound
}
