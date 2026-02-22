//
//  TodoQuery.swift
//  DevLog
//
//  Created by opfic on 2/21/26.
//

struct TodoQuery {
    let kind: TodoKind?
    let keyword: String?
    let isPinned: Bool?
    let pageSize: Int

    init(
        kind: TodoKind? = nil,
        keyword: String? = nil,
        isPinned: Bool? = nil,
        pageSize: Int = 20
    ) {
        self.kind = kind
        self.keyword = keyword
        self.isPinned = isPinned
        self.pageSize = pageSize
    }
}
