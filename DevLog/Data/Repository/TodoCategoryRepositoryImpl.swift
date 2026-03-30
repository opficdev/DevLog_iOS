//
//  TodoCategoryRepositoryImpl.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

final class TodoCategoryRepositoryImpl: TodoCategoryRepository {
    private let todoCategoryService: TodoCategoryService

    init(todoCategoryService: TodoCategoryService) {
        self.todoCategoryService = todoCategoryService
    }

    func fetchPreferences() async throws -> [TodoCategoryPreference] {
        try await todoCategoryService.fetchPreferences()
    }

    func updatePreferences(_ preferences: [TodoCategoryPreference]) async throws {
        try await todoCategoryService.updatePreferences(preferences)
    }
}
