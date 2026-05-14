//
//  TodoCategoryService.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation
import DevLogDomain
import DevLogDataDTO

public protocol TodoCategoryService {
    func fetchPreferences() async throws -> [TodoCategoryPreference]
    func updatePreferences(_ preferences: [TodoCategoryPreference]) async throws
}
