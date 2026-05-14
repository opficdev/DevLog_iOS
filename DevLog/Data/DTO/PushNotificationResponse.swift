//
//  PushNotificationResponse.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

import Foundation

public struct PushNotificationResponse {
    public let id: String
    public let title: String
    public let body: String
    public let receivedAt: Date
    public let isRead: Bool
    public let todoId: String
    public let todoCategory: TodoCategoryResponse

    public init(
        id: String,
        title: String,
        body: String,
        receivedAt: Date,
        isRead: Bool,
        todoId: String,
        todoCategory: TodoCategoryResponse
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
