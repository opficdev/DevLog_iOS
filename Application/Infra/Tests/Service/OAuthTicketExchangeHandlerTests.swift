//
//  OAuthTicketExchangeHandlerTests.swift
//  InfraTests
//
//  Created by opfic on 7/12/26.
//

import Foundation
import Testing
@testable import Infra

struct OAuthTicketExchangeHandlerTests {
    @Test("app challenge는 app verifier의 SHA-256 base64url 값이다")
    func app_challenge는_app_verifier의_SHA_256_base64url_값이다() {
        let handler = OAuthTicketExchangeHandler(
            appVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        )

        #expect(handler.appChallenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test("생성된 app verifier는 64자리 소문자 16진수다")
    func 생성된_app_verifier는_64자리_소문자_16진수다() {
        let handler = OAuthTicketExchangeHandler()
        let allowedCharacters = CharacterSet(charactersIn: "0123456789abcdef")

        #expect(handler.appVerifier.count == 64)
        #expect(handler.appVerifier.unicodeScalars.allSatisfy(allowedCharacters.contains))
    }

    @Test("DevLog OAuth callback에서 ticket을 추출한다")
    func DevLog_OAuth_callback에서_ticket을_추출한다() throws {
        let handler = OAuthTicketExchangeHandler(appVerifier: "verifier")
        let callbackURL = try #require(
            URL(string: "DevLog://oauth-callback?ticket=one-time-ticket")
        )

        #expect(try handler.ticket(from: callbackURL) == "one-time-ticket")
    }

    @Test("다른 callback host는 거부한다")
    func 다른_callback_host는_거부한다() throws {
        let handler = OAuthTicketExchangeHandler(appVerifier: "verifier")
        let callbackURL = try #require(
            URL(string: "DevLog://unexpected?ticket=one-time-ticket")
        )

        #expect(throws: SocialLoginError.self) {
            try handler.ticket(from: callbackURL)
        }
    }

    @Test("ticket이 없는 callback은 거부한다")
    func ticket이_없는_callback은_거부한다() throws {
        let handler = OAuthTicketExchangeHandler(appVerifier: "verifier")
        let callbackURL = try #require(URL(string: "DevLog://oauth-callback"))

        #expect(throws: SocialLoginError.self) {
            try handler.ticket(from: callbackURL)
        }
    }
}
