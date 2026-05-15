//
//  PushNotification.swift
//  DevLog
//
//  Created by opfic on 6/28/25.
//

import Foundation

public struct PushNotification: Hashable {
    public let id: String
    public let title: String
    public let body: String
    public let receivedAt: Date
    public var isRead: Bool
    public let todoId: String
    public let todoCategory: TodoCategory

    public init(
        id: String,
        title: String,
        body: String,
        receivedAt: Date,
        isRead: Bool,
        todoId: String,
        todoCategory: TodoCategory
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.receivedAt = receivedAt
        self.isRead = isRead
        self.todoId = todoId
        self.todoCategory = todoCategory
    }
}
