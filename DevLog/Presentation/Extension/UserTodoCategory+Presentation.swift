//
//  UserTodoCategory+Presentation.swift
//  DevLog
//
//  Created by opfic on 3/29/26.
//

import SwiftUI

extension UserTodoCategory: Identifiable {
    var id: String { category }
}

extension UserTodoCategory: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(category)
        hasher.combine(name)
        hasher.combine(colorHex)
    }
}

extension UserTodoCategory {
    var symbolName: String { "tray.fill" }

    var localizedName: String { name }

    var color: Color { .gray }
}
