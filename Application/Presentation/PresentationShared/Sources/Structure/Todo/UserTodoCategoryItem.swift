//
//  UserTodoCategoryItem.swift
//  Presentation
//
//  Created by opfic on 3/30/26.
//

import SwiftUI
import Domain

public struct UserTodoCategoryItem: Identifiable, Hashable {
    public let userTodoCategory: UserTodoCategory

    public init(from userTodoCategory: UserTodoCategory) {
        self.userTodoCategory = userTodoCategory
    }

    public var id: String { userTodoCategory.id }

    public var symbolName: String { "tray.fill" }

    public var localizedName: String { userTodoCategory.name }

    public var color: Color { Color(hexString: userTodoCategory.colorHex) ?? .gray }
}
