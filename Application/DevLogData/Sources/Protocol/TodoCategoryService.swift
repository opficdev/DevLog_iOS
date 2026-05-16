//
//  TodoCategoryService.swift
//  DevLogData
//
//  Created by opfic on 5/14/26.
//

import Foundation
import DevLogDomain

public protocol TodoCategoryService {
    func fetchPreferences() async throws -> [TodoCategoryPreference]
    func updatePreferences(_ preferences: [TodoCategoryPreference]) async throws
}
