//
//  FetchTodoCategoryPreferencesUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

final class FetchTodoCategoryPreferencesUseCaseImpl: FetchTodoCategoryPreferencesUseCase {
    private let todoCategoryRepository: TodoCategoryRepository

    init(_ todoCategoryRepository: TodoCategoryRepository) {
        self.todoCategoryRepository = todoCategoryRepository
    }

    func execute() async throws -> [TodoCategoryPreference] {
        try await todoCategoryRepository.fetchPreferences()
    }
}
