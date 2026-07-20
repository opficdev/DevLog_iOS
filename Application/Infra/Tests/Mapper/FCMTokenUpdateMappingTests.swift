//
//  FCMTokenUpdateMappingTests.swift
//  InfraTests
//
//  Created by opfic on 7/20/26.
//

import Data
import Testing
@testable import Infra

struct FCMTokenUpdateMappingTests {
    @Test("FCM token 저장 데이터는 token과 앱 언어 코드만 포함한다")
    func firestoreData_FCM_token과_앱_언어_코드만_포함한다() {
        let update = FCMTokenUpdate(
            fcmToken: "fcm-token",
            code: .english
        )

        let data = update.firestoreData

        #expect(data.count == 2)
        #expect(data["fcmToken"] as? String == "fcm-token")
        #expect(data["pushLanguageCode"] as? String == "en")
        #expect(data["pushLocalizationVersion"] == nil)
    }
}
