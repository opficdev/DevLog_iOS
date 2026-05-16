//
//  TodoCategoryPreferenceResponse.swift
//  DevLogData
//
//  Created by opfic on 5/16/26.
//

import Foundation

public struct TodoCategoryPreferenceResponse: Equatable {
    public enum Category: Equatable {
        case system(String)
        case user(UserCategory)
    }

    public struct UserCategory: Equatable {
        public let id: String
        public let name: String
        public let colorHex: String

        public init(
            id: String,
            name: String,
            colorHex: String
        ) {
            self.id = id
            self.name = name
            self.colorHex = colorHex
        }
    }

    public let category: Category
    public let isVisible: Bool

    public init(
        category: Category,
        isVisible: Bool
    ) {
        self.category = category
        self.isVisible = isVisible
    }
}
