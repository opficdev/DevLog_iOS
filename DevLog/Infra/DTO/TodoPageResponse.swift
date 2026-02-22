//
//  TodoPageResponse.swift
//  DevLog
//
//  Created by opfic on 2/21/26.
//

struct TodoPageResponse {
    let items: [TodoResponse]
    let nextCursor: TodoCursorResponse?
}
