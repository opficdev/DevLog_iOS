//
//  UserTodoCategory.swift
//  DevLogDomain
//
//  Created by opfic on 3/29/26.
//

import Foundation

public struct UserTodoCategory: Hashable {
    public var id: String
    public var name: String
    public var colorHex: String

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
