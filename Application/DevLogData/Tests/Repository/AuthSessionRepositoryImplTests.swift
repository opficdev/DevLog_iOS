//
//  AuthSessionRepositoryImplTests.swift
//  DevLogDataTests
//
//  Created by opfic on 6/8/26.
//

import Combine
import Foundation
import Testing
@testable import DevLogData

struct AuthSessionRepositoryImplTests {
    private enum Key {
        static let preferences = "TodoCategory.preferences"
    }

    @Test("로그인 세션 true는 category preference 캐싱 후 방출한다")
    func 로그인_세션_true는_category_preference_캐싱_후_방출한다() async throws {
        let preference = makePreferenceResponse()
        let authService = AuthSessionAuthServiceSpy()
        let todoCategoryService = AuthSessionTodoCategoryServiceSpy(preferences: [preference])
        let store = AuthSessionMemoryCacheStoreSpy()
        let provider = AuthSessionStateProviderSpy()
        let repository = AuthSessionRepositoryImpl(
            authService: authService,
            todoCategoryService: todoCategoryService,
            store: store,
            provider: provider
        )
        let valueTask = Task {
            for await value in repository.observeSignedIn().values where value {
                return value
            }
            return false
        }

        authService.send(true)

        #expect(await valueTask.value)
        #expect(store.value(forKey: Key.preferences) == [preference])
        #expect(await todoCategoryService.fetchCategoryPreferencesCallCount() == 1)
        #expect(provider.events == [true])
    }

    @Test("로그아웃 세션은 category preference 캐시를 제거한다")
    func 로그아웃_세션은_category_preference_캐시를_제거한다() async throws {
        let preference = makePreferenceResponse()
        let authService = AuthSessionAuthServiceSpy(isSignedIn: true)
        let todoCategoryService = AuthSessionTodoCategoryServiceSpy(preferences: [preference])
        let store = AuthSessionMemoryCacheStoreSpy()
        let provider = AuthSessionStateProviderSpy()
        store.setValue([preference], forKey: Key.preferences)
        let repository = AuthSessionRepositoryImpl(
            authService: authService,
            todoCategoryService: todoCategoryService,
            store: store,
            provider: provider
        )
        let valueTask = Task {
            for await value in repository.observeSignedIn().values where value == false {
                return value
            }
            return true
        }

        authService.send(false)

        #expect(await valueTask.value == false)
        #expect(store.value(forKey: Key.preferences) == Optional<[TodoCategoryPreferenceResponse]>.none)
        #expect(provider.events == [false])
    }

    private func makePreferenceResponse() -> TodoCategoryPreferenceResponse {
        TodoCategoryPreferenceResponse(
            category: .user(
                TodoCategoryPreferenceResponse.UserCategory(
                    id: "user-category-id",
                    name: "User Category",
                    colorHex: "#FFFFFF"
                )
            ),
            isVisible: true
        )
    }
}

private final class AuthSessionStateProviderSpy: AuthSessionStateProvider {
    private(set) var events = [Bool]()

    func publish(_ isSignedIn: Bool) {
        events.append(isSignedIn)
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        Empty().eraseToAnyPublisher()
    }
}

private final class AuthSessionAuthServiceSpy: AuthService {
    private let subject: CurrentValueSubject<Bool, Never>

    var uid: String? { nil }
    var providerIDs: [String] { [] }
    var currentUserEmail: String? { nil }
    var providerCount: Int { 0 }

    init(isSignedIn: Bool = false) {
        self.subject = CurrentValueSubject<Bool, Never>(isSignedIn)
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func beginSignIn() { }
    func completeSignIn() { }
    func cancelSignIn() { }
    func getProviderID() async throws -> String? { nil }
    func deleteCurrentUser() async throws { }
    func clearCurrentSession() async throws { }

    func send(_ isSignedIn: Bool) {
        subject.send(isSignedIn)
    }
}

private actor AuthSessionTodoCategoryServiceSpy: TodoCategoryService {
    private let preferences: [TodoCategoryPreferenceResponse]
    private let fetchDelay: Duration?
    private var fetchCategoryPreferencesCount = 0

    init(
        preferences: [TodoCategoryPreferenceResponse],
        fetchDelay: Duration? = nil
    ) {
        self.preferences = preferences
        self.fetchDelay = fetchDelay
    }

    func fetchCategoryPreferences() async throws -> [TodoCategoryPreferenceResponse] {
        fetchCategoryPreferencesCount += 1
        if let fetchDelay {
            try await Task.sleep(for: fetchDelay)
        }
        return preferences
    }

    func updateCategoryPreferences(_ preferences: [TodoCategoryPreferenceResponse]) async throws { }

    func fetchCategoryPreferencesCallCount() -> Int {
        fetchCategoryPreferencesCount
    }
}

private final class AuthSessionMemoryCacheStoreSpy: MemoryCacheStore {
    private var values = [String: Data]()

    func value<T: Codable>(forKey key: String) -> T? {
        guard let data = values[key] else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

    func setValue<T: Codable>(_ value: T?, forKey key: String) {
        guard let value else {
            values.removeValue(forKey: key)
            return
        }

        values[key] = try? JSONEncoder().encode(value)
    }
}
