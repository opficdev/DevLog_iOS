//
//  FCMTokenUpdateTests.swift
//  DataTests
//
//  Created by opfic on 7/20/26.
//

import Testing
@testable import Data

struct FCMTokenUpdateTests {
    @Test("한국어 localization identifier를 한국어 코드로 정규화한다")
    func pushLanguageCode_한국어_identifier를_한국어_코드로_정규화한다() {
        #expect(PushLanguageCode(identifier: "ko") == .korean)
        #expect(PushLanguageCode(identifier: "ko-KR") == .korean)
    }

    @Test("영어 localization identifier를 영어 코드로 정규화한다")
    func pushLanguageCode_영어_identifier를_영어_코드로_정규화한다() {
        #expect(PushLanguageCode(identifier: "en") == .english)
        #expect(PushLanguageCode(identifier: "en_US") == .english)
    }

    @Test("누락되거나 지원하지 않는 localization identifier는 한국어 코드로 정규화한다")
    func pushLanguageCode_누락되거나_지원하지_않는_identifier는_한국어_코드로_정규화한다() {
        #expect(PushLanguageCode(identifier: nil) == .korean)
        #expect(PushLanguageCode(identifier: "ja") == .korean)
    }
}
