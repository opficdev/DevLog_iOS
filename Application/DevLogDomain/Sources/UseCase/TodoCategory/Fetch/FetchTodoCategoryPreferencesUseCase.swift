//
//  FetchTodoCategoryPreferencesUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/30/26.
//

public protocol FetchTodoCategoryPreferencesUseCase {
    func execute() async throws -> [TodoCategoryPreference]
}
