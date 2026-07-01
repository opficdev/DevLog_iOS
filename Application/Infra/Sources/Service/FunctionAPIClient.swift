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
        try await send(
            endpoint,
            payload: EmptyPayload(),
            requiresAuthentication: requiresAuthentication
        )
    }

    private func client() throws -> NXAPIClient {
        try apiClient.get()
    }
}

struct FunctionAPIEndpoint<Response: Decodable>: NXEndpoint {
    let method: NXHTTPMethod
    let path: String
}

struct FunctionAPIResponse: Decodable {
    let accessToken: String?
    let customToken: String?
    let refreshToken: String?
    let token: String?
}

struct EmptyAPIResponse: Decodable {}

private struct EmptyPayload: Encodable {}

private struct FunctionAPIErrorBody: Decodable {
    let code: String
    let message: String?
}

private struct FunctionAPIServerErrorDecoder: NXServerErrorDecoder {
    func decodeServerError(
        data: Data,
        response: HTTPURLResponse,
        decoder: JSONDecoder
    ) -> (any Error)? {
        guard let body = try? decoder.decode(
            FunctionAPIErrorBody.self,
            from: data
        ) else { return nil }

        switch body.code {
        case EmailFetchError.emailNotFound.code:
            return EmailFetchError.emailNotFound
        case EmailFetchError.emailMismatch.code:
            return EmailFetchError.emailMismatch
        default:
            return nil
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
    var apiEmailFetchError: EmailFetchError? {
        guard let error = self as? NXError,
              case let .server(
            statusCode: _,
            data: _,
            underlying: underlying
        ) = error else { return nil }

        return underlying as? EmailFetchError
    }
}
