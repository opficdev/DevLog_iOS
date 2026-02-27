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

    init(from notification: PushNotification) {
        self.id = notification.id
        self.title = notification.title
        self.body = notification.body
        self.receivedAt = notification.receivedAt
        self.isRead = notification.isRead
        self.todoID = notification.todoID
        self.todoKind = notification.todoKind
    }
}
