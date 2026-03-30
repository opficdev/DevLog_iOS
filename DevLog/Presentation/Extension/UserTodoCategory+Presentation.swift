//
//  UserTodoCategory+Presentation.swift
//  DevLog
//
//  Created by opfic on 3/29/26.
//

import SwiftUI

extension UserTodoCategory: Identifiable { }

extension UserTodoCategory: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(colorHex)
    }
}

extension UserTodoCategory {
    var symbolName: String { "tray.fill" }

    var localizedName: String { name }

    var color: Color { Color(hexString: colorHex) ?? .gray }
}
