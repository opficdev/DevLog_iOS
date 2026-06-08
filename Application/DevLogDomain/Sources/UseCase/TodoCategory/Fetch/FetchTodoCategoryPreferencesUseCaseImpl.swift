//
//  FetchTodoCategoryPreferencesUseCaseImpl.swift
//  DevLogDomain
//
//  Created by opfic on 3/30/26.
//

public final class FetchTodoCategoryPreferencesUseCaseImpl: FetchTodoCategoryPreferencesUseCase {
    private let todoCategoryRepository: TodoCategoryRepository

    init(_ todoCategoryRepository: TodoCategoryRepository) {
        self.todoCategoryRepository = todoCategoryRepository
    }

    public func execute() async throws -> [TodoCategoryPreference] {
        try await todoCategoryRepository.fetchCategoryPreferences()
    }
}
