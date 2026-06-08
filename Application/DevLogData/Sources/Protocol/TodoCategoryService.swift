//
//  TodoCategoryService.swift
//  DevLogData
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol TodoCategoryService {
    func fetchCategoryPreferences() async throws -> [TodoCategoryPreferenceResponse]
    func updateCategoryPreferences(_ preferences: [TodoCategoryPreferenceResponse]) async throws
}
