//
//  PushNotificationItemTests.swift
//  NotificationTabTests
//
//  Created by opfic on 7/19/26.
//

import Foundation
import Testing
@testable import NotificationTab

struct PushNotificationItemTests {
    @Test("Todo 제목이 있는 의미 기반 알림을 지연 일정 문구로 변환한다")
    func todoDueTomorrowWithTitleUsesLocalizedContent() {
        let notification = makePushNotification(
            id: "notification-1",
            number: 1,
            content: .todoDueTomorrow(todoTitle: "테스트 작성")
        )
        let item = PushNotificationItem(from: notification)

        #expect(item.title == String(localized: "push_notification_todo_due_title"))
        #expect(
            item.body == String.localizedStringWithFormat(
                String(localized: "push_notification_todo_due_tomorrow_format"),
                "테스트 작성"
            )
        )
    }

    @Test("제목 없는 Todo 알림을 전용 문구로 변환한다")
    func todoDueTomorrowWithoutTitleUsesDedicatedLocalizedContent() {
        let notification = makePushNotification(
            id: "notification-1",
            number: 1,
            content: .todoDueTomorrow(todoTitle: nil)
        )
        let item = PushNotificationItem(from: notification)

        #expect(item.title == String(localized: "push_notification_todo_due_title"))
        #expect(item.body == String(localized: "push_notification_todo_due_tomorrow_without_title"))
    }

    @Test("빈 제목을 제목 없는 Todo 전용 문구로 변환한다")
    func todoDueTomorrowWithEmptyTitleUsesDedicatedLocalizedContent() {
        let notification = makePushNotification(
            id: "notification-1",
            number: 1,
            content: .todoDueTomorrow(todoTitle: "")
        )
        let item = PushNotificationItem(from: notification)

        #expect(item.body == String(localized: "push_notification_todo_due_tomorrow_without_title"))
    }

    @Test("기존 알림은 저장된 제목과 본문을 그대로 사용한다")
    func legacyNotificationUsesStoredTitleAndBody() {
        let notification = makePushNotification(id: "notification-1", number: 1)
        let item = PushNotificationItem(from: notification)

        #expect(item.title == "title-1")
        #expect(item.body == "body-1")
    }
}
