//
//  TodoReferenceItem.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import Foundation

struct TodoReferenceItem: Equatable {
    let id: String
    let title: String
    let category: TodoCategoryItem

    init(from todoReference: TodoReference) {
        self.id = todoReference.id
        self.title = todoReference.title
        self.category = TodoCategoryItem(from: todoReference.category)
    }
}
