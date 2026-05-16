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

    func fetchPreferences() async throws -> [TodoCategoryPreference] {
        do {
            return try await todoCategoryService.fetchPreferences()
        } catch {
            throw error.toDomain()
        }
    }

    func updatePreferences(_ preferences: [TodoCategoryPreference]) async throws {
        do {
            try await todoCategoryService.updatePreferences(preferences)
        } catch {
            throw error.toDomain()
        }
    }
}
