//
//  TodoCategoryService.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol TodoCategoryService {
    func fetchPreferences() async throws -> [TodoCategoryPreference]
    func updatePreferences(_ preferences: [TodoCategoryPreference]) async throws
}
