//
//  TodoCategoryService.swift
//  DevLogData
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol TodoCategoryService {
    func fetchPreferences() async throws -> [TodoCategoryPreferenceResponse]
    func updatePreferences(_ preferences: [TodoCategoryPreferenceResponse]) async throws
}
