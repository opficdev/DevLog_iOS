//
//  TodoCategoryRepositoryImpl.swift
//  DevLogData
//
//  Created by opfic on 3/30/26.
//

import DevLogDomain

final class TodoCategoryRepositoryImpl: TodoCategoryRepository {
    private enum Key {
        static let preferences = "TodoCategory.preferences"
    }

    private let todoCategoryService: TodoCategoryService
    private let store: UserDefaultsStore

    init(
        todoCategoryService: TodoCategoryService,
        store: UserDefaultsStore
    ) {
        self.todoCategoryService = todoCategoryService
        self.store = store
    }

    func fetchCategoryPreferences() async throws -> [TodoCategoryPreference] {
        do {
            if let preferences: [TodoCategoryPreferenceResponse] = store.value(forKey: Key.preferences) {
                return preferences.toDomain()
            }

            let responses = try await todoCategoryService.fetchCategoryPreferences()
            store.setValue(responses, forKey: Key.preferences)
            return responses.toDomain()
        } catch {
            throw error.toDomain()
        }
    }

    func updateCategoryPreferences(_ preferences: [TodoCategoryPreference]) async throws {
        do {
            let responses = preferences.map(TodoCategoryPreferenceResponse.fromDomain)
            try await todoCategoryService.updateCategoryPreferences(responses)
            store.setValue(responses, forKey: Key.preferences)
        } catch {
            throw error.toDomain()
        }
    }
}
