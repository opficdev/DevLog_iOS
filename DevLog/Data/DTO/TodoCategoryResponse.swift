//
//  TodoCategoryResponse.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import Foundation

enum TodoCategoryResponse {
    case raw(String)
    case decoded(TodoCategory)
}
