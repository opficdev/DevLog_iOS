//
//  PushNotificationDecoderTests.swift
//  InfraTests
//
//  Created by opfic on 7/19/26.
//

import Testing
import Data
@testable import Infra

struct PushNotificationDecoderTests {
    @Test("todoDueTomorrow 내용은 Todo 제목을 해석한다")
    func todoDueTomorrow_내용은_Todo_제목을_해석한다() {
        let content = PushNotificationDecoder.decode([
            "contentType": "todoDueTomorrow",
            "contentArguments": ["todoTitle": "테스트 작성"]
        ])

        #expect(content == .todoDueTomorrow(todoTitle: "테스트 작성"))
    }

    @Test("제목 없는 todoDueTomorrow 내용은 제목을 nil로 해석한다")
    func todoDueTomorrow_제목이_없으면_제목을_nil로_해석한다() {
        let content = PushNotificationDecoder.decode([
            "contentType": "todoDueTomorrow",
            "contentArguments": [:]
        ])

        #expect(content == .todoDueTomorrow(todoTitle: nil))
    }

    @Test("기존 알림 필드는 의미 기반 내용 없이 해석한다")
    func legacy_알림_필드는_의미_기반_내용_없이_해석한다() {
        let content = PushNotificationDecoder.decode([:])

        #expect(content == nil)
    }

    @Test("알 수 없는 내용 타입은 의미 기반 내용 없이 해석한다")
    func unknown_내용_타입은_의미_기반_내용_없이_해석한다() {
        let content = PushNotificationDecoder.decode([
            "contentType": "unknown",
            "contentArguments": ["todoTitle": "테스트 작성"]
        ])

        #expect(content == nil)
    }
}
