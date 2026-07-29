//
//  PushNotificationMappingTests.swift
//  DataTests
//
//  Created by opfic on 7/20/26.
//

import Foundation
import Testing
import Domain
@testable import Data

struct PushNotificationMappingTests {
    @Test("Todo 제목을 알림 도메인 모델에 전달한다")
    func Todo_제목을_알림_도메인_모델에_전달한다() throws {
        let response = PushNotificationResponse(
            id: "notification-1",
            todoTitle: "테스트 작성",
            receivedAt: Date(timeIntervalSince1970: 1),
            isRead: false,
            todoId: "todo-1",
            todoCategory: .decoded(.system(.feature))
        )

        let notification = try response.toDomain()

        #expect(notification.todoTitle == "테스트 작성")
    }

    @Test("기존 알림 문구를 Legacy 래퍼로 전달한다")
    func 기존_알림_문구를_Legacy_래퍼로_전달한다() throws {
        let response = PushNotificationResponse(
            id: "notification-1",
            legacy: .init(title: "기존 제목", body: "기존 본문"),
            receivedAt: Date(timeIntervalSince1970: 1),
            isRead: false,
            todoId: "todo-1",
            todoCategory: .decoded(.system(.feature))
        )

        let notification = try response.toDomain()
        let legacy = try #require(notification.legacy)

        #expect(legacy.title == "기존 제목")
        #expect(legacy.body == "기존 본문")
    }
}
