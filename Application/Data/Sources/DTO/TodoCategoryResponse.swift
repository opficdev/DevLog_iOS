//
//  TodoCategoryResponse.swift
//  Data
//
//  Created by opfic on 3/30/26.
//

import Foundation
import Domain

public enum TodoCategoryResponse {
    case raw(String)
    case decoded(TodoCategory)
}
