//
//  TodoCategoryRepository.swift
//  Domain
//
//  Created by opfic on 3/30/26.
//

public protocol TodoCategoryRepository {
    func fetchCategoryPreferences() async throws -> [TodoCategoryPreference]
    func updateCategoryPreferences(_ preferences: [TodoCategoryPreference]) async throws
}
