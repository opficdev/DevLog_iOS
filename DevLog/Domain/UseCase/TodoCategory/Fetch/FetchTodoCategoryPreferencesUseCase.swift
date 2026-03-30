//
//  FetchTodoCategoryPreferencesUseCase.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

protocol FetchTodoCategoryPreferencesUseCase {
    func execute() async throws -> [TodoCategoryPreference]
}
