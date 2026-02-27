//
//  PushNotificationItem.swift
//  DevLog
//
//  Created by 최윤진 on 2/27/26.
//

import Foundation

struct PushNotificationItem: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let receivedAt: Date
    var isRead: Bool
    let todoID: String
    let todoKind: TodoKind

    private init(
        id: String,
        title: String,
        body: String,
        receivedAt: Date,
        isRead: Bool,
        todoID: String,
        todoKind: TodoKind
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.receivedAt = receivedAt
        self.isRead = isRead
        self.todoID = todoID
        self.todoKind = todoKind
    }

    init(from notification: PushNotification) {
        self.init(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            receivedAt: notification.receivedAt,
            isRead: notification.isRead,
            todoID: notification.todoID,
            todoKind: notification.todoKind
        )
    }
}
