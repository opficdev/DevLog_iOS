//
//  UserServiceImplTests.swift
//  InfraTests
//
//  Created by opfic on 7/19/26.
//

import Testing
@testable import Infra

struct UserServiceImplTests {
    @Test("FCM token 필드는 현지화 지원 버전을 함께 구성한다")
    func tokenField_FCM_token과_현지화_지원_버전을_구성한다() {
        let field = UserServiceImpl.makeTokenField(fcmToken: "fcm-token")

        #expect(field["fcmToken"] as? String == "fcm-token")
        #expect(field["pushLocalizationVersion"] as? Int == 1)
        #expect(field["languageCode"] == nil)
    }

    @Test("FCM token이 없으면 token 필드를 구성하지 않는다")
    func tokenField_FCM_token이_없으면_비어_있다() {
        let field = UserServiceImpl.makeTokenField(fcmToken: nil)

        #expect(field.isEmpty)
    }
}
