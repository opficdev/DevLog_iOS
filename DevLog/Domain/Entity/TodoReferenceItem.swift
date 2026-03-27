//
//  TodoReferenceItem.swift
//  DevLog
//
//  Created by opfic on 3/25/26.
//

import Foundation

struct TodoReferenceItem: Identifiable, Equatable {
    let id: String
    let title: String
    let category: TodoCategory
}
