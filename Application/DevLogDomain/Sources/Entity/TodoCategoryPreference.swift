//
//  TodoCategoryPreference.swift
//  DevLogDomain
//
//  Created by opfic on 3/30/26.
//

import Foundation

public struct TodoCategoryPreference: Equatable {
    public let category: TodoCategory
    public var isVisible: Bool

    public init(
        category: TodoCategory,
        isVisible: Bool
    ) {
        self.category = category
        self.isVisible = isVisible
    }
}
