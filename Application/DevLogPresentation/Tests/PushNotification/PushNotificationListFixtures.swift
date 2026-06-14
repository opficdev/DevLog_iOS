//
//  PushNotificationListFixtures.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/12/26.
//

import DevLogDomain
import Foundation

func makePushNotification(
    id: String,
    number: Int,
    isRead: Bool = false
) -> PushNotification {
    PushNotification(
        id: id,
        title: "title-\(number)",
        body: "body-\(number)",
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
