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

    private let todoTitle: String?
    @available(*, deprecated, message: "todoTitle 기반 알림을 사용한다.")
    private let legacy: PushNotification.Legacy?

    public var title: String {
        if let legacy {
            return legacy.title
        }
        return String(localized: "push_notification_todo_due_title")
    }

    public var body: String {
        if let legacy {
            return legacy.body
        }
        guard let todoTitle,
              !todoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return String(localized: "push_notification_todo_due_tomorrow_without_title")
        }
        return String.localizedStringWithFormat(
            String(localized: "push_notification_todo_due_tomorrow_format"),
            todoTitle
        )
    }

    public init(from notification: PushNotification) {
        self.id = notification.id
        self.receivedAt = notification.receivedAt
        self.isRead = notification.isRead
        self.todoId = notification.todoId
        self.todoCategory = notification.todoCategory
        self.todoTitle = notification.todoTitle
        self.legacy = notification.legacy
    }
}
