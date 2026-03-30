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
    let todoId: String
    let todoCategory: TodoCategory

    init(from notification: PushNotification) {
        self.id = notification.id
        self.title = notification.title
        self.body = notification.body
        self.receivedAt = notification.receivedAt
        self.isRead = notification.isRead
        self.todoId = notification.todoId
        self.todoCategory = notification.todoCategory
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
