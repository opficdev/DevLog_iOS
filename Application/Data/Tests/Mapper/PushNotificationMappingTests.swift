//
//  PushNotificationMappingTests.swift
//  DataTests
//
//  Created by opfic on 7/19/26.
//

import Foundation
import Testing
import Domain
@testable import Data

struct PushNotificationMappingTests {
    @Test("Todo 마감 알림 응답은 의미 기반 내용을 변환한다")
    func Todo_마감_알림_응답은_의미_기반_내용을_변환한다() throws {
        let response = makeResponse(
            content: .todoDueTomorrow(todoTitle: "테스트 작성")
        )

        let notification = try response.toDomain()

        #expect(notification.content == .todoDueTomorrow(todoTitle: "테스트 작성"))
        #expect(notification.title == "fallback-title")
        #expect(notification.body == "fallback-body")
    }

    @Test("기존 푸시 알림 응답은 의미 기반 내용 없이 변환한다")
    func 기존_푸시_알림_응답은_의미_기반_내용_없이_변환한다() throws {
        let response = makeResponse()

        let notification = try response.toDomain()

        #expect(notification.content == nil)
        #expect(notification.title == "fallback-title")
        #expect(notification.body == "fallback-body")
    }

    private func makeResponse(
        content: PushNotificationResponse.Content? = nil
    ) -> PushNotificationResponse {
        PushNotificationResponse(
            id: "notification-id",
            title: "fallback-title",
            body: "fallback-body",
            receivedAt: Date(timeIntervalSince1970: 1),
            isRead: false,
            todoId: "todo-id",
            todoCategory: .decoded(.system(.feature)),
            content: content
        )
    }
}
