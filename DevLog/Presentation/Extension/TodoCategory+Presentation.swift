//
//  TodoCategory+Presentation.swift
//  DevLog
//
//  Created by opfic on 3/29/26.
//

import SwiftUI

extension TodoCategory: Identifiable {
    var id: String {
        switch self {
        case .system(let category):
            return category.id
        case .user(let category):
            return category.id
        }
    }
}

extension TodoCategory: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .system(let category):
            hasher.combine(0)
            hasher.combine(category)
        case .user(let category):
            hasher.combine(1)
            hasher.combine(category)
        }
    }
}

extension TodoCategory {
    var symbolName: String {
        switch self {
        case .system(let category):
            return category.symbolName
        case .user(let category):
            return category.symbolName
        }
    }

    var localizedName: String {
        switch self {
        case .system(let category):
            return category.localizedName
        case .user(let category):
            return category.localizedName
        }
    }

    var color: Color {
        switch self {
        case .system(let category):
            return category.color
        case .user(let category):
            return category.color
        }
    }
}
