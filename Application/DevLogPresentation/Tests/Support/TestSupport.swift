//
//  TestSupport.swift
//  DevLogPresentationTests
//
//  Created by opfic on 4/6/26.
//

import Testing
import Foundation
import Combine
import DevLogCore
import DevLogDomain
@testable import DevLogPresentation

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

final class FetchPushNotificationsUseCaseSpy: FetchPushNotificationsUseCase {
    var pushNotificationPage: PushNotificationPage
    private(set) var executeCallCount = 0

    init(pushNotificationPage: PushNotificationPage) {
        self.pushNotificationPage = pushNotificationPage
    }

    func execute(
        _ query: PushNotificationQuery,
        cursor: PushNotificationCursor?
    ) async throws -> PushNotificationPage {
        executeCallCount += 1
        return pushNotificationPage
    }

    func observe(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPage, Error> {
        Empty().eraseToAnyPublisher()
    }
}

final class SignInUseCaseSpy: SignInUseCase {
    var error: Error?
    var shouldSuspend = false
    private(set) var calledProviders: [AuthProvider] = []
    private(set) var successfulProviders = [AuthProvider]()
    private var continuation: CheckedContinuation<Void, Never>?
    private var shouldResume = false

    func execute(_ provider: AuthProvider) async throws {
        calledProviders.append(provider)

        if shouldSuspend {
            await withCheckedContinuation { continuation in
                if shouldResume {
                    shouldResume = false
                    continuation.resume()
                } else {
                    self.continuation = continuation
                }
            }
        }

        if let error {
            throw error
        }

        successfulProviders.append(provider)
    }

    func resume() {
        guard let continuation else {
            shouldResume = true
            return
        }
        self.continuation = nil
        continuation.resume()
    }
}

final class DeletePushNotificationUseCaseSpy: DeletePushNotificationUseCase {
    private(set) var calledNotificationIds: [String] = []

    func execute(_ notificationID: String) async throws {
        calledNotificationIds.append(notificationID)
    }
}

final class UndoDeletePushNotificationUseCaseSpy: UndoDeletePushNotificationUseCase {
    private(set) var calledNotificationIds: [String] = []

    func execute(_ notificationID: String) async throws {
        calledNotificationIds.append(notificationID)
    }
}

final class TogglePushNotificationReadUseCaseSpy: TogglePushNotificationReadUseCase {
    private(set) var calledTodoIds: [String] = []

    func execute(_ todoId: String) async throws {
        calledTodoIds.append(todoId)
    }
}

final class FetchPushNotificationQueryUseCaseSpy: FetchPushNotificationQueryUseCase {
    var pushNotificationQuery = PushNotificationQuery.default

    func execute() -> PushNotificationQuery {
        pushNotificationQuery
    }
}

final class UpdatePushNotificationQueryUseCaseSpy: UpdatePushNotificationQueryUseCase {
    private(set) var queries: [PushNotificationQuery] = []

    func execute(_ query: PushNotificationQuery) {
        queries.append(query)
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
    private(set) var calledUrlStrings: [String] = []

    func execute(_ urlString: String) async throws {
        calledUrlStrings.append(urlString)
    }
}

final class DeleteWebPageUseCaseSpy: DeleteWebPageUseCase {
    private(set) var calledUrlStrings: [String] = []

    func execute(_ urlString: String) async throws {
        calledUrlStrings.append(urlString)
    }
}

final class UndoDeleteWebPageUseCaseSpy: UndoDeleteWebPageUseCase {
    private(set) var calledUrlStrings: [String] = []

    func execute(_ urlString: String) async throws {
        calledUrlStrings.append(urlString)
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

final class FetchTodosUseCaseSpy: FetchTodosUseCase {
    var todoPage = TodoPage(items: [], nextCursor: nil)
    private(set) var queries: [TodoQuery] = []

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)
        return todoPage
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
