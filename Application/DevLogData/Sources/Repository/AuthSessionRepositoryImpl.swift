//
//  AuthSessionRepositoryImpl.swift
//  DevLogData
//
//  Created by 최윤진 on 12/31/25.
//

import Combine
import DevLogDomain

final class AuthSessionRepositoryImpl: AuthSessionRepository {
    private enum Key {
        static let preferences = "TodoCategory.preferences"
    }

    private let authService: AuthService
    private let todoCategoryService: TodoCategoryService
    private let store: UserDefaultsStore
    private let provider: AuthSessionStateProvider

    init(
        authService: AuthService,
        todoCategoryService: TodoCategoryService,
        store: UserDefaultsStore,
        provider: AuthSessionStateProvider
    ) {
        self.authService = authService
        self.todoCategoryService = todoCategoryService
        self.store = store
        self.provider = provider
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        authService.observeSignedIn()
            .removeDuplicates()
            .map { [self] isSignedIn in
                Future { promise in
                    Task {
                        if isSignedIn {
                            await self.cachePreferencesIfNeeded()
                        } else {
                            self.clearPreferencesCache()
                        }
                        self.provider.publish(isSignedIn)
                        promise(.success(isSignedIn))
                    }
                }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}

private extension AuthSessionRepositoryImpl {
    func cachePreferencesIfNeeded() async {
        if store.value(forKey: Key.preferences) as [TodoCategoryPreferenceResponse]? != nil {
            return
        }

        guard let preferences = try? await todoCategoryService.fetchCategoryPreferences() else {
            return
        }

        store.setValue(preferences, forKey: Key.preferences)
    }

    func clearPreferencesCache() {
        store.setValue(Optional<[TodoCategoryPreferenceResponse]>.none, forKey: Key.preferences)
    }
}
