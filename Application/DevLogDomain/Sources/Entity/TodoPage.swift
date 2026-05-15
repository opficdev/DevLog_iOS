//
//  TodoPage.swift
//  DevLog
//
//  Created by opfic on 2/21/26.
//

public struct TodoPage {
    public let items: [Todo]
    public let nextCursor: TodoCursor?

    public init(
        items: [Todo],
        nextCursor: TodoCursor?
    ) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
