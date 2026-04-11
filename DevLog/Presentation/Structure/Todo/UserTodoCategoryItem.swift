//
//  UserTodoCategoryItem.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import SwiftUI

struct UserTodoCategoryItem: Identifiable, Hashable {
    let userTodoCategory: UserTodoCategory

    init(from userTodoCategory: UserTodoCategory) {
        self.userTodoCategory = userTodoCategory
    }

    var id: String { userTodoCategory.id }

    var symbolName: String { "tray.fill" }

    var localizedName: String { userTodoCategory.name }

    var color: Color { Color(hexString: userTodoCategory.colorHex) ?? .gray }
}
