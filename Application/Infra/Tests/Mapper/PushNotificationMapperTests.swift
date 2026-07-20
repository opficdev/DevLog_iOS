//
//  PushNotificationMapperTests.swift
//  InfraTests
//
//  Created by opfic on 7/20/26.
//

import FirebaseFirestore
import Foundation
import Testing
@testable import Infra

struct PushNotificationMapperTests {
    @Test("Todo 제목 문서를 신규 응답으로 변환한다")
    func Todo_제목_문서를_신규_응답으로_변환한다() throws {
        var data = makeData()
        data[PushNotificationFieldKey.todoTitle.rawValue] = "테스트 작성"

        let response = try #require(
            PushNotificationMapper().map(documentID: "notification-1", data: data)
        )

        #expect(response.todoTitle == "테스트 작성")
    }

    @Test("신규 필드와 기존 필드가 함께 있으면 신규 응답을 우선한다")
    func 신규_필드와_기존_필드가_함께_있으면_신규_응답을_우선한다() throws {
        var data = makeData()
        data[PushNotificationFieldKey.todoTitle.rawValue] = "테스트 작성"
        data[PushNotificationFieldKey.title.rawValue] = "기존 제목"
        data[PushNotificationFieldKey.body.rawValue] = "기존 본문"

        let response = try #require(
            PushNotificationMapper().map(documentID: "notification-1", data: data)
        )

        #expect(response.todoTitle == "테스트 작성")
    }

    @Test("기존 제목과 본문 문서를 Legacy 응답으로 변환한다")
    func 기존_제목과_본문_문서를_Legacy_응답으로_변환한다() throws {
        var data = makeData()
        data[PushNotificationFieldKey.title.rawValue] = "기존 제목"
        data[PushNotificationFieldKey.body.rawValue] = "기존 본문"

        let response = try #require(
            PushNotificationMapper().map(documentID: "notification-1", data: data)
        )
        let legacy = try #require(response.legacy)

        #expect(legacy.title == "기존 제목")
        #expect(legacy.body == "기존 본문")
    }

    @Test("Todo 제목이 null이면 기존 제목과 본문을 우선한다")
    func Todo_제목이_null이면_기존_제목과_본문을_우선한다() throws {
        var data = makeData()
        data[PushNotificationFieldKey.todoTitle.rawValue] = NSNull()
        data[PushNotificationFieldKey.title.rawValue] = "기존 제목"
        data[PushNotificationFieldKey.body.rawValue] = "기존 본문"

        let response = try #require(
            PushNotificationMapper().map(documentID: "notification-1", data: data)
        )
        let legacy = try #require(response.legacy)

        #expect(legacy.title == "기존 제목")
        #expect(legacy.body == "기존 본문")
    }

    private func makeData() -> [String: Any] {
        [
            PushNotificationFieldKey.receivedAt.rawValue: Timestamp(
                date: Date(timeIntervalSince1970: 1)
            ),
            PushNotificationFieldKey.isRead.rawValue: false,
            PushNotificationFieldKey.todoId.rawValue: "todo-1",
            PushNotificationFieldKey.todoCategory.rawValue: "feature",
            PushNotificationFieldKey.isDeleted.rawValue: false
        ]
    }
}
