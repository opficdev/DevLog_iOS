//
//  FunctionAPIEndpointTests.swift
//  InfraTests
//
//  Created by opfic on 7/10/26.
//

import AuthenticationServices
import Foundation
import Testing
@testable import Infra

struct FunctionAPIEndpointTests {
    @Test("Apple 인증 challenge endpoint는 인증 challenge 경로를 사용한다")
    func Apple_인증_challenge_endpoint는_인증_challenge_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<AppleChallengeResponse>
            .requestAppleChallenge

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/apple/challenges")
    }

    @Test("Apple custom token endpoint는 인증 custom token 경로를 사용한다")
    func Apple_custom_token_endpoint는_인증_custom_token_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<FirebaseCustomTokenResponse>.requestAppleCustomToken

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/apple/custom-token")
    }

    @Test("Apple 계정 연결 endpoint는 PUT 인증 account link 경로를 사용한다")
    func Apple_계정_연결_endpoint는_PUT_인증_account_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.linkAppleAccount

        #expect(endpoint.method.rawValue == "PUT")
        #expect(endpoint.path == "/auth/apple/account-link")
    }

    @Test("Apple 계정 연결 해제 endpoint는 DELETE 인증 account link 경로를 사용한다")
    func Apple_계정_연결_해제_endpoint는_DELETE_인증_account_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.unlinkAppleAccount

        #expect(endpoint.method.rawValue == "DELETE")
        #expect(endpoint.path == "/auth/apple/account-link")
    }

    @Test("Apple grant 정리 endpoint는 DELETE 인증 access token 경로를 사용한다")
    func Apple_grant_정리_endpoint는_DELETE_인증_access_token_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.revokeAppleAccessToken

        #expect(endpoint.method.rawValue == "DELETE")
        #expect(endpoint.path == "/auth/apple/access-token")
    }

    @Test("Apple custom token 요청은 display name을 포함할 수 있다")
    func Apple_custom_token_요청은_display_name을_포함할_수_있다() throws {
        let request = AppleCustomTokenRequest(
            challengeId: "challenge-id",
            authorizationCode: "authorization-code",
            displayName: "Apple User"
        )

        #expect(
            try encodedKeys(request) == [
                "challengeId",
                "authorizationCode",
                "displayName"
            ]
        )
    }

    @Test("Apple custom token 요청은 없는 display name을 인코딩하지 않는다")
    func Apple_custom_token_요청은_없는_display_name을_인코딩하지_않는다() throws {
        let request = AppleCustomTokenRequest(
            challengeId: "challenge-id",
            authorizationCode: "authorization-code",
            displayName: nil
        )

        #expect(try encodedKeys(request) == ["challengeId", "authorizationCode"])
    }

    @Test("Apple 이름은 custom token 요청용 display name으로 변환한다")
    func Apple_이름은_custom_token_요청용_display_name으로_변환한다() {
        var fullName = PersonNameComponents()
        fullName.givenName = "Apple"

        #expect(fullName.displayName == "Apple")
    }

    @Test("비어 있는 Apple 이름은 display name으로 변환하지 않는다")
    func 비어_있는_Apple_이름은_display_name으로_변환하지_않는다() {
        #expect(PersonNameComponents().displayName == nil)
    }

    @Test("Apple 계정 연결 요청은 credential email을 포함할 수 있다")
    func Apple_계정_연결_요청은_credential_email을_포함할_수_있다() throws {
        let request = AppleAccountLinkRequest(
            challengeId: "challenge-id",
            authorizationCode: "authorization-code",
            credentialEmail: "apple@example.com"
        )

        #expect(
            try encodedKeys(request) == [
                "challengeId",
                "authorizationCode",
                "credentialEmail"
            ]
        )
    }

    @Test("Apple 계정 연결 요청은 없는 credential email을 인코딩하지 않는다")
    func Apple_계정_연결_요청은_없는_credential_email을_인코딩하지_않는다() throws {
        let request = AppleAccountLinkRequest(
            challengeId: "challenge-id",
            authorizationCode: "authorization-code",
            credentialEmail: nil
        )

        #expect(try encodedKeys(request) == ["challengeId", "authorizationCode"])
    }

    @Test("Apple 인증 요청 nonce는 서버 hashed nonce를 사용한다")
    @MainActor
    func Apple_인증_요청_nonce는_서버_hashed_nonce를_사용한다() {
        let request = AppleAuthenticationServiceImpl.makeAuthorizationRequest(
            hashedNonce: "server-hashed-nonce"
        )

        #expect(request.nonce == "server-hashed-nonce")
        #expect(request.requestedScopes == [.fullName, .email])
    }

    @Test("Apple provider 연결 충돌을 공통 인증 오류로 분류한다")
    func Apple_provider_연결_충돌을_공통_인증_오류로_분류한다() throws {
        let code = "apple-provider-link-conflict"
        let data = try JSONEncoder().encode(FunctionAPIErrorFixture(code: code))
        let response = try #require(
            HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 409,
                httpVersion: nil,
                headerFields: nil
            )
        )

        let error = FunctionAPIServerErrorDecoder().decodeServerError(
            data: data,
            response: response,
            decoder: JSONDecoder()
        )

        #expect(error as? AuthenticationAPIError == .providerLinkConflict)
    }

    @Test("Google provider 연결 충돌을 공통 인증 오류로 분류한다")
    func Google_provider_연결_충돌을_공통_인증_오류로_분류한다() throws {
        let data = try JSONEncoder().encode(
            FunctionAPIErrorFixture(code: "google-provider-link-conflict")
        )
        let response = try #require(
            HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 409,
                httpVersion: nil,
                headerFields: nil
            )
        )

        let error = FunctionAPIServerErrorDecoder().decodeServerError(
            data: data,
            response: response,
            decoder: JSONDecoder()
        )

        #expect(error as? AuthenticationAPIError == .providerLinkConflict)
    }

    @Test("마지막 provider 서버 오류를 공통 인증 오류로 분류한다")
    func 마지막_provider_서버_오류를_공통_인증_오류로_분류한다() throws {
        let data = try JSONEncoder().encode(
            FunctionAPIErrorFixture(code: "last-provider")
        )
        let response = try #require(
            HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 412,
                httpVersion: nil,
                headerFields: nil
            )
        )

        let error = FunctionAPIServerErrorDecoder().decodeServerError(
            data: data,
            response: response,
            decoder: JSONDecoder()
        )

        #expect(error as? AuthenticationAPIError == .lastProvider)
    }

    @Test("OAuth 인증 session 요청은 app challenge만 인코딩한다")
    func OAuth_인증_session_요청은_app_challenge만_인코딩한다() throws {
        let request = OAuthAuthenticationSessionRequest(appChallenge: "app-challenge")

        #expect(try encodedKeys(request) == ["appChallenge"])
    }

    @Test("OAuth 인증 ticket 요청은 ticket과 app verifier만 인코딩한다")
    func OAuth_인증_ticket_요청은_ticket과_app_verifier만_인코딩한다() throws {
        let request = OAuthAuthenticationTicketRequest(
            ticket: "ticket",
            appVerifier: "app-verifier"
        )

        #expect(try encodedKeys(request) == ["ticket", "appVerifier"])
    }

    @Test("Google authorization code 요청은 server auth code만 인코딩한다")
    func Google_authorization_code_요청은_server_auth_code만_인코딩한다() throws {
        let request = GoogleAuthorizationCodeRequest(
            serverAuthCode: "server-auth-code"
        )

        #expect(try encodedKeys(request) == ["serverAuthCode"])
    }

    @Test("GitHub 로그인 session endpoint는 sign-in-sessions 경로를 사용한다")
    func GitHub_로그인_session_endpoint는_sign_in_sessions_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<OAuthAuthenticationSessionResponse>
            .requestGithubSignInSession

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/github/sign-in-sessions")
    }

    @Test("GitHub custom token endpoint는 custom-token 경로를 사용한다")
    func GitHub_custom_token_endpoint는_custom_token_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<FirebaseCustomTokenResponse>
            .requestGithubCustomToken

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/github/custom-token")
    }

    @Test("GitHub 계정 연결 session endpoint는 account-link-sessions 경로를 사용한다")
    func GitHub_계정_연결_session_endpoint는_account_link_sessions_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<OAuthAuthenticationSessionResponse>
            .requestGithubAccountLinkSession

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/github/account-link-sessions")
    }

    @Test("GitHub 계정 연결 endpoint는 PUT account-link 경로를 사용한다")
    func GitHub_계정_연결_endpoint는_PUT_account_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.linkGithubAccount

        #expect(endpoint.method.rawValue == "PUT")
        #expect(endpoint.path == "/auth/github/account-link")
    }

    @Test("GitHub 계정 연결 해제 endpoint는 DELETE account-link 경로를 사용한다")
    func GitHub_계정_연결_해제_endpoint는_DELETE_account_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.unlinkGithubAccount

        #expect(endpoint.method.rawValue == "DELETE")
        #expect(endpoint.path == "/auth/github/account-link")
    }

    @Test("Google authorization code custom token endpoint는 인증 코드 경로를 사용한다")
    func Google_authorization_code_custom_token_endpoint는_인증_코드_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<FirebaseCustomTokenResponse>
            .requestGoogleAuthorizationCustomToken

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/google/authorization-code/custom-token")
    }

    @Test("Google 계정 연결 endpoint는 PUT 인증 코드 경로를 사용한다")
    func Google_계정_연결_endpoint는_PUT_인증_코드_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.linkGoogleAccount

        #expect(endpoint.method.rawValue == "PUT")
        #expect(endpoint.path == "/auth/google/authorization-code/account-link")
    }

    @Test("Google 계정 연결 해제 endpoint는 DELETE account-link 경로를 사용한다")
    func Google_계정_연결_해제_endpoint는_DELETE_account_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.unlinkGoogleAccount

        #expect(endpoint.method.rawValue == "DELETE")
        #expect(endpoint.path == "/auth/google/account-link")
    }

    @Test("Google access token endpoint는 DELETE access-token 경로를 사용한다")
    func Google_access_token_endpoint는_DELETE_access_token_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.revokeGoogleAccessToken

        #expect(endpoint.method.rawValue == "DELETE")
        #expect(endpoint.path == "/auth/google/access-token")
    }
}

private struct FunctionAPIErrorFixture: Encodable {
    let code: String
}

private func encodedKeys(_ value: some Encodable) throws -> Set<String> {
    let data = try JSONEncoder().encode(value)
    let object = try JSONSerialization.jsonObject(with: data)
    let dictionary = try #require(object as? [String: Any])
    return Set(dictionary.keys)
}
