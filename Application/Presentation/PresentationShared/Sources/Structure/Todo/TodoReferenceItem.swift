//
//  TodoReferenceItem.swift
//  PresentationShared
//
//  Created by opfic on 3/30/26.
//

import Foundation
import Domain

public struct TodoReferenceItem: Equatable {
    public let id: String
    public let title: String
    public let category: TodoCategoryItem

    public init(from todoReference: TodoReference) {
        self.id = todoReference.id
        self.title = todoReference.title
        self.category = TodoCategoryItem(from: todoReference.category)
    }
}
