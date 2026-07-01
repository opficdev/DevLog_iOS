//
//  TodoReference.swift
//  Domain
//
//  Created by opfic on 3/25/26.
//

import Foundation

public struct TodoReference: Hashable {
    public let id: String
    public let title: String
    public let category: TodoCategory

    public init(
        id: String,
        title: String,
        category: TodoCategory
    ) {
        self.id = id
        self.title = title
        self.category = category
    }
}
