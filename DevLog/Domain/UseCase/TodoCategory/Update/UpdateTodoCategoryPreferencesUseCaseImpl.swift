//
//  UpdateTodoCategoryPreferencesUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

final class UpdateTodoCategoryPreferencesUseCaseImpl: UpdateTodoCategoryPreferencesUseCase {
    private let todoCategoryRepository: TodoCategoryRepository

    init(_ todoCategoryRepository: TodoCategoryRepository) {
        self.todoCategoryRepository = todoCategoryRepository
    }

    func execute(_ preferences: [TodoCategoryPreference]) async throws {
        try await todoCategoryRepository.updatePreferences(preferences)
    }
}
