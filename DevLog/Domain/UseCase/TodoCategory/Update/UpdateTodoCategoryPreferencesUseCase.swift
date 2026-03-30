//
//  UpdateTodoCategoryPreferencesUseCase.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

protocol UpdateTodoCategoryPreferencesUseCase {
    func execute(_ preferences: [TodoCategoryPreference]) async throws
}
