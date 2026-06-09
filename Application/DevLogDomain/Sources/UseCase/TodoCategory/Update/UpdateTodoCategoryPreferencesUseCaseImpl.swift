//
//  UpdateTodoCategoryPreferencesUseCaseImpl.swift
//  DevLogDomain
//
//  Created by opfic on 3/30/26.
//

public final class UpdateTodoCategoryPreferencesUseCaseImpl: UpdateTodoCategoryPreferencesUseCase {
    private let todoCategoryRepository: TodoCategoryRepository

    init(_ todoCategoryRepository: TodoCategoryRepository) {
        self.todoCategoryRepository = todoCategoryRepository
    }

    public func execute(_ preferences: [TodoCategoryPreference]) async throws {
        try await todoCategoryRepository.updateCategoryPreferences(preferences)
    }
}
