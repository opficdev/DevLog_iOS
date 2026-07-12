//
//  FunctionAPIClient.swift
//  Infra
//
//  Created by opfic on 6/26/26.
//

import FirebaseAuth
import Foundation
import Data
import Nexa

final class FunctionAPIClient {
    static let shared = FunctionAPIClient()

    private let apiClient: Result<NXAPIClient, Error>

    private init() {
        let authTokenProvider = FirebaseAuthTokenProvider()
        apiClient = Result {
            try NXAPIClient(
                configuration: NXClientConfiguration(
                    baseURL: FirebaseConfiguration.functionAPIBaseURL(),
                    headers: ["Accept": "application/json"],
                    serverErrorDecoder: FunctionAPIServerErrorDecoder(),
                    authTokenProvider: authTokenProvider
                )
            )
        }
    }

    func send(
        _ endpoint: FunctionAPIEndpoint<EmptyAPIResponse>,
        payload: some Encodable,
        requiresAuthentication: Bool = true
    ) async throws {
        var request = try client()
            .request(endpoint)
            .json(payload)

        if requiresAuthentication {
            request = request.authorized()
        }

        _ = try await request.raw()
    }

    func send(
        _ endpoint: FunctionAPIEndpoint<EmptyAPIResponse>,
        requiresAuthentication: Bool = true
    ) async throws {
        var request = try client()
            .request(endpoint)

        if requiresAuthentication {
            request = request.authorized()
        }

        _ = try await request.raw()
    }

    func send<Response: Decodable>(
        _ endpoint: FunctionAPIEndpoint<Response>,
        payload: some Encodable,
        requiresAuthentication: Bool = true
    ) async throws -> Response {
        var request = try client()
            .request(endpoint)
            .json(payload)

        if requiresAuthentication {
            request = request.authorized()
        }

        return try await request.send()
    }

    func send<Response: Decodable>(
        _ endpoint: FunctionAPIEndpoint<Response>,
        requiresAuthentication: Bool = true
    ) async throws -> Response {
        var request = try client()
            .request(endpoint)

        if requiresAuthentication {
            request = request.authorized()
        }

        return try await request.send()
    }

    private func client() throws -> NXAPIClient {
        try apiClient.get()
    }
}

struct FunctionAPIEndpoint<Response: Decodable>: NXEndpoint {
    let method: NXHTTPMethod
    let path: String
}

struct OAuthAuthenticationSessionRequest: Encodable {
    let appChallenge: String
}

struct OAuthAuthenticationSessionResponse: Decodable {
    let authorizationURL: URL
}

struct OAuthAuthenticationTicketRequest: Encodable {
    let ticket: String
    let appVerifier: String
}

struct AppleChallengeResponse: Decodable {
    let challengeId: String
    let hashedNonce: String
}

struct FirebaseCustomTokenResponse: Decodable {
    let customToken: String
}

struct AppleCustomTokenRequest: Encodable {
    let challengeId: String
    let authorizationCode: String
}

struct AppleAccountLinkRequest: Encodable {
    let challengeId: String
    let authorizationCode: String
    let credentialEmail: String?
}

struct EmptyAPIResponse: Decodable {}

private struct FunctionAPIErrorBody: Decodable {
    let code: String
    let message: String?
}

private enum FunctionAPIErrorCode: String {
    case emailNotFound = "email-not-found"
    case emailMismatch = "email-mismatch"
    case githubEmailConflict = "github-email-changed-account-conflict"
    case appleProviderLinkConflict = "apple-provider-link-conflict"
    case lastProvider = "last-provider"
}

enum AppleAuthenticationAPIError: Error, Equatable {
    case providerLinkConflict
}

enum AuthenticationAPIError: Error, Equatable {
    case lastProvider
}

struct FunctionAPIServerErrorDecoder: NXServerErrorDecoder {
    func decodeServerError(
        data: Data,
        response: HTTPURLResponse,
        decoder: JSONDecoder
    ) -> (any Error)? {
        guard let body = try? decoder.decode(
            FunctionAPIErrorBody.self,
            from: data
        ), let code = FunctionAPIErrorCode(rawValue: body.code) else { return nil }

        switch code {
        case .emailNotFound:
            return EmailError.notFound
        case .emailMismatch:
            return EmailError.mismatch
        case .githubEmailConflict:
            return EmailError.githubEmailConflict
        case .appleProviderLinkConflict:
            return AppleAuthenticationAPIError.providerLinkConflict
        case .lastProvider:
            return AuthenticationAPIError.lastProvider
        }
    }
}

private actor FirebaseAuthTokenProvider: NXAuthTokenProvider {
    func currentAccessToken() async throws -> String? {
        try await Auth.auth().currentUser?.getIDToken()
    }

    func refreshAccessToken() async throws -> String? {
        try await Auth.auth().currentUser?.getIDToken(forcingRefresh: true)
    }
}

extension Error {
    var apiEmailError: EmailError? {
        functionAPIUnderlyingError as? EmailError
    }

    var apiAppleAuthenticationError: AppleAuthenticationAPIError? {
        functionAPIUnderlyingError as? AppleAuthenticationAPIError
    }

    var apiAuthenticationError: AuthenticationAPIError? {
        functionAPIUnderlyingError as? AuthenticationAPIError
    }

    private var functionAPIUnderlyingError: (any Error)? {
        guard let error = self as? NXError,
              case let .server(statusCode: _, data: _, underlying: underlying) = error else {
            return nil
        }

        return underlying
    }
}
