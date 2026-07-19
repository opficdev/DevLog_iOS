//
//  PushNotificationItem.swift
//  NotificationTab
//
//  Created by 최윤진 on 2/27/26.
//

import Foundation
import Domain

public struct PushNotificationItem: Identifiable, Hashable {
    public let id: String
    public var isHidden = false
    public let receivedAt: Date
    public var isRead: Bool
    public let todoId: String
    public let todoCategory: TodoCategory

    private let legacyTitle: String
    private let legacyBody: String
    private let content: PushNotificationContent?

    public var title: String {
        switch content {
        case .todoDueTomorrow:
            return String(localized: "push_notification_todo_due_title")
        case nil:
            return legacyTitle
        }
    }

    public var body: String {
        switch content {
        case .todoDueTomorrow(let todoTitle):
            guard let todoTitle,
                  !todoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return String(localized: "push_notification_todo_due_tomorrow_without_title")
            }
            return String.localizedStringWithFormat(
                String(localized: "push_notification_todo_due_tomorrow_format"),
                todoTitle
            )
        case nil:
            return legacyBody
        }
    }

    public init(from notification: PushNotification) {
        self.id = notification.id
        self.receivedAt = notification.receivedAt
        self.isRead = notification.isRead
        self.todoId = notification.todoId
        self.todoCategory = notification.todoCategory
        self.legacyTitle = notification.title
        self.legacyBody = notification.body
        self.content = notification.content
    }
}
