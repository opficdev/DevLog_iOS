//
//  TodoPageResponse.swift
//  DevLogData
//
//  Created by opfic on 2/21/26.
//

public struct TodoPageResponse {
    public let items: [TodoResponse]
    public let nextCursor: TodoCursorDTO?

    public init(
        items: [TodoResponse],
        nextCursor: TodoCursorDTO?
    ) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
