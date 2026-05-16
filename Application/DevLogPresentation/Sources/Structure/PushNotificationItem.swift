//
//  PushNotificationItem.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 2/27/26.
//

import Foundation
import DevLogDomain

public struct PushNotificationItem: Identifiable, Hashable {
    public let id: String
    public var isHidden = false
    public let title: String
    public let body: String
    public let receivedAt: Date
    public var isRead: Bool
    public let todoId: String
    public let todoCategory: TodoCategory

    init(from notification: PushNotification) {
        self.id = notification.id
        self.title = notification.title
        self.body = notification.body
        self.receivedAt = notification.receivedAt
        self.isRead = notification.isRead
        self.todoId = notification.todoId
        self.todoCategory = notification.todoCategory
    }
}
