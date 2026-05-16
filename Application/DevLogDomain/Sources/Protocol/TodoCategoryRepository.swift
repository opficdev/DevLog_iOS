//
//  TodoCategoryRepository.swift
//  DevLogDomain
//
//  Created by opfic on 3/30/26.
//

public protocol TodoCategoryRepository {
    func fetchPreferences() async throws -> [TodoCategoryPreference]
    func updatePreferences(_ preferences: [TodoCategoryPreference]) async throws
}
