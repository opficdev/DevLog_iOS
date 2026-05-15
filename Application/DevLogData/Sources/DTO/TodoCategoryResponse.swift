//
//  TodoCategoryResponse.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import Foundation
import DevLogDomain

public enum TodoCategoryResponse {
    case raw(String)
    case decoded(TodoCategory)
}
