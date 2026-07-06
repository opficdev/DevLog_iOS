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
    var todoCategoryPreferences: [TodoCategoryPreference] = []

    func execute() async throws -> [TodoCategoryPreference] {
        todoCategoryPreferences
    }
}

final class UpdateTodoCategoryPreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCase {
    private(set) var updates: [[TodoCategoryPreference]] = []

    func execute(_ preferences: [TodoCategoryPreference]) async throws {
        updates.append(preferences)
    }
}

final class AddWebPageUseCaseSpy: AddWebPageUseCase {
    var error: Error?
    private(set) var calledUrlStrings: [String] = []

    func execute(_ urlString: String) async throws {
        calledUrlStrings.append(urlString)
        if let error {
            throw error
        }
    }
}

final class DeleteWebPageUseCaseSpy: DeleteWebPageUseCase {
    private(set) var calls: [(id: String, urlString: String)] = []

    func execute(id: String, urlString: String) async throws {
        calls.append((id, urlString))
    }
}

final class UndoDeleteWebPageUseCaseSpy: UndoDeleteWebPageUseCase {
    private(set) var calledIDs: [String] = []

    func execute(_ id: String) async throws {
        calledIDs.append(id)
    }
}

final class FetchTodosUseCaseSpy: FetchTodosUseCase {
    var todoPage = TodoPage(items: [], nextCursor: nil)
    private(set) var queries: [TodoQuery] = []

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)
        return todoPage
    }
}

final class FetchWebPagesUseCaseSpy: FetchWebPagesUseCase {
    var webPages: [WebPage]
    private(set) var calledQueries: [String] = []

    init(webPages: [WebPage]) {
        self.webPages = webPages
    }

    func execute(_ query: String) async throws -> [WebPage] {
        calledQueries.append(query)
        return webPages
    }
}

final class ObserveNetworkConnectivityUseCaseSpy: ObserveNetworkConnectivityUseCase {
    let currentValueSubject = CurrentValueSubject<Bool, Never>(true)

    func observe() -> AnyPublisher<Bool, Never> {
        currentValueSubject.eraseToAnyPublisher()
    }
}
