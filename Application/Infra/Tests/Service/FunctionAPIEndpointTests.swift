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
        let endpoint = FunctionAPIEndpoint<AppleCustomTokenResponse>.requestAppleCustomToken

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/apple/custom-token")
    }

    @Test("Apple 계정 연결 endpoint는 PUT 인증 account link 경로를 사용한다")
    func Apple_계정_연결_endpoint는_PUT_인증_account_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<AppleOperationResponse>.linkAppleAccount

        #expect(endpoint.method.rawValue == "PUT")
        #expect(endpoint.path == "/auth/apple/account-link")
    }

    @Test("Apple 계정 연결 해제 endpoint는 DELETE 인증 account link 경로를 사용한다")
    func Apple_계정_연결_해제_endpoint는_DELETE_인증_account_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<AppleOperationResponse>.unlinkAppleAccount

        #expect(endpoint.method.rawValue == "DELETE")
        #expect(endpoint.path == "/auth/apple/account-link")
    }

    @Test("Apple grant 정리 endpoint는 DELETE 인증 access token 경로를 사용한다")
    func Apple_grant_정리_endpoint는_DELETE_인증_access_token_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<AppleOperationResponse>.revokeAppleAccessToken

        #expect(endpoint.method.rawValue == "DELETE")
        #expect(endpoint.path == "/auth/apple/access-token")
    }

    @Test("Apple custom token 요청은 challenge와 authorization code만 인코딩한다")
    func Apple_custom_token_요청은_challenge와_authorization_code만_인코딩한다() throws {
        let request = AppleCustomTokenRequest(
            challengeId: "challenge-id",
            authorizationCode: "authorization-code"
        )

        #expect(try encodedKeys(request) == ["challengeId", "authorizationCode"])
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

    @Test(
        "Apple 서버 오류를 앱 인증 오류 원인으로 분류한다",
        arguments: [
            ("apple-provider-link-conflict", AppleAuthenticationAPIError.providerLinkConflict),
            ("last-provider", AppleAuthenticationAPIError.lastProvider)
        ]
    )
    func Apple_서버_오류를_앱_인증_오류_원인으로_분류한다(
        code: String,
        expected: AppleAuthenticationAPIError
    ) throws {
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

        #expect(error as? AppleAuthenticationAPIError == expected)
    }

    @Test("GitHub provider 연결 endpoint는 인증 link 경로를 사용한다")
    func 깃허브_provider_연결_endpoint는_인증_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<GithubAuthenticationResponse>.linkGithubProvider

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/github/link")
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
