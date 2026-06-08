//
//  TodoCategoryRepositoryImpl.swift
//  DevLogData
//
//  Created by opfic on 3/30/26.
//

import DevLogDomain

final class TodoCategoryRepositoryImpl: TodoCategoryRepository {
    private let todoCategoryService: TodoCategoryService

    init(todoCategoryService: TodoCategoryService) {
        self.todoCategoryService = todoCategoryService
    }

    func fetchCategoryPreferences() async throws -> [TodoCategoryPreference] {
        do {
            return try await todoCategoryService.fetchCategoryPreferences().toDomain()
        } catch {
            throw error.toDomain()
        }
    }

    func updateCategoryPreferences(_ preferences: [TodoCategoryPreference]) async throws {
        do {
            try await todoCategoryService.updateCategoryPreferences(
                preferences.map(TodoCategoryPreferenceResponse.fromDomain)
            )
        } catch {
            throw error.toDomain()
        }
    }
}
