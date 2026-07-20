//
//  PushNotificationListFixtures.swift
//  NotificationTabTests
//
//  Created by opfic on 6/12/26.
//

import Domain
import Foundation

func makePushNotification(
    id: String,
    number: Int,
    isRead: Bool = false,
    todoTitle: String? = nil
) -> PushNotification {
    PushNotification(
        id: id,
        todoTitle: todoTitle,
        receivedAt: Date(timeIntervalSince1970: Double(number)),
        isRead: isRead,
        todoId: "todo-\(number)",
        todoCategory: .system(.feature)
    )
}

@available(*, deprecated, message: "makePushNotification을 사용한다.")
func makeLegacyPushNotification(
    id: String,
    number: Int,
    isRead: Bool = false,
    title: String,
    body: String
) -> PushNotification {
    PushNotification(
        id: id,
        legacy: .init(title: title, body: body),
        receivedAt: Date(timeIntervalSince1970: Double(number)),
        isRead: isRead,
        todoId: "todo-\(number)",
        todoCategory: .system(.feature)
    )
}

func makePushNotificationCursor(documentID: String) -> PushNotificationCursor {
    PushNotificationCursor(
        receivedAt: .now,
        documentID: documentID
    )
}
