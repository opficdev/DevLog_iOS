//
//  FirebaseCrashlyticsCollectionPolicyTests.swift
//  InfraTests
//
//  Created by opfic on 7/22/26.
//

import Foundation
import Testing
@testable import Infra

struct FirebaseCrashlyticsCollectionPolicyTests {
    @Test("Info.plist true 값을 수집 활성 상태로 해석한다")
    func Info_plist_true_값을_수집_활성_상태로_해석한다() {
        let policy = FirebaseCrashlyticsCollectionPolicy(infoDictionaryValue: true)

        #expect(policy.isCollectionEnabled)
    }

    @Test("Info.plist false 값을 수집 비활성 상태로 해석한다")
    func Info_plist_false_값을_수집_비활성_상태로_해석한다() {
        let policy = FirebaseCrashlyticsCollectionPolicy(infoDictionaryValue: false)

        #expect(!policy.isCollectionEnabled)
    }

    @Test("Info.plist 값이 누락되면 수집 비활성 상태로 해석한다")
    func Info_plist_값이_누락되면_수집_비활성_상태로_해석한다() {
        let policy = FirebaseCrashlyticsCollectionPolicy(infoDictionaryValue: nil)

        #expect(!policy.isCollectionEnabled)
    }

    @Test("Info.plist 값의 형식이 잘못되면 수집 비활성 상태로 해석한다")
    func Info_plist_값의_형식이_잘못되면_수집_비활성_상태로_해석한다() {
        let policy = FirebaseCrashlyticsCollectionPolicy(infoDictionaryValue: "true")

        #expect(!policy.isCollectionEnabled)
    }

    @Test("Info.plist 값이 숫자이면 수집 비활성 상태로 해석한다")
    func Info_plist_값이_숫자이면_수집_비활성_상태로_해석한다() {
        let policy = FirebaseCrashlyticsCollectionPolicy(
            infoDictionaryValue: NSNumber(value: 1)
        )

        #expect(!policy.isCollectionEnabled)
    }

    @Test("현재 수집 상태가 비활성이면 보고서를 삭제한 뒤 목표 상태를 저장한다", arguments: [false, true])
    func 현재_수집_상태가_비활성이면_보고서를_삭제한_뒤_목표_상태를_저장한다(
        isCollectionEnabled: Bool
    ) {
        let policy = FirebaseCrashlyticsCollectionPolicy(
            infoDictionaryValue: isCollectionEnabled
        )

        #expect(
            policy.actions(currentCollectionEnabled: false) == [
                .deleteUnsentReports,
                .setCollectionEnabled(isCollectionEnabled)
            ]
        )
    }

    @Test("현재 수집 상태가 활성이면 목표 상태만 저장한다", arguments: [false, true])
    func 현재_수집_상태가_활성이면_목표_상태만_저장한다(
        isCollectionEnabled: Bool
    ) {
        let policy = FirebaseCrashlyticsCollectionPolicy(
            infoDictionaryValue: isCollectionEnabled
        )

        #expect(
            policy.actions(currentCollectionEnabled: true) == [
                .setCollectionEnabled(isCollectionEnabled)
            ]
        )
    }
}
