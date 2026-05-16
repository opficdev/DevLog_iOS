//
//  TodoReferenceResponse.swift
//  DevLogData
//
//  Created by opfic on 3/30/26.
//

import Foundation
import DevLogDomain

public struct TodoReferenceResponse {
    public let id: String
    public let number: Int
    public let title: String
    public let category: TodoCategoryResponse

    public init(
        id: String,
        number: Int,
        title: String,
        category: TodoCategoryResponse
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.category = category
    }
}
