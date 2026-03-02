//
//  TodoQuery.swift
//  DevLog
//
//  Created by opfic on 2/21/26.
//

import Foundation

struct TodoQuery {
    let kind: TodoKind?
    let keyword: String?
    let isPinned: Bool?
    let createdAtFrom: Date?
    let createdAtTo: Date?
    let createdAtDescending: Bool
    let pageSize: Int
    let fetchAllPages: Bool

    init(
        kind: TodoKind? = nil,
        keyword: String? = nil,
        isPinned: Bool? = nil,
        createdAtFrom: Date? = nil,
        createdAtTo: Date? = nil,
        createdAtDescending: Bool = true,
        pageSize: Int = 20,
        fetchAllPages: Bool = false
    ) {
        self.kind = kind
        self.keyword = keyword
        self.isPinned = isPinned
        self.createdAtFrom = createdAtFrom
        self.createdAtTo = createdAtTo
        self.createdAtDescending = createdAtDescending
        self.pageSize = pageSize
        self.fetchAllPages = fetchAllPages
    }
}
