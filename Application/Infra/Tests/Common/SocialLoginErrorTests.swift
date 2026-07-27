//
//  SocialLoginErrorTests.swift
//  InfraTests
//
//  Created by opfic on 7/26/26.
//

import Foundation
import Testing
@testable import Infra

struct SocialLoginErrorTests {
    @Test("Google 로그인 취소 오류를 소셜 로그인 취소로 분류한다")
    func Google_로그인_취소_오류를_소셜_로그인_취소로_분류한다() {
        let error = NSError(
            domain: "com.google.GIDSignIn",
            code: -5
        )

        #expect(error.isSocialLoginCancelled)
    }

    @Test("Google 로그인의 다른 오류를 취소로 분류하지 않는다")
    func Google_로그인의_다른_오류를_취소로_분류하지_않는다() {
        let error = NSError(
            domain: "com.google.GIDSignIn",
            code: -1
        )

        #expect(!error.isSocialLoginCancelled)
    }
}
