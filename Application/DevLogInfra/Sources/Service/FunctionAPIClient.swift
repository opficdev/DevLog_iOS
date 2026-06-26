//
//  FunctionAPIClient.swift
//  DevLogInfra
//
//  Created by opfic on 6/26/26.
//

import FirebaseAuth
import Foundation
import DevLogData
import Nexa

struct FunctionAPIClient {
    private let authTokenProvider = FirebaseAuthTokenProvider()

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

private struct FunctionAPIServerErrorDecoder: NXServerErrorDecoder {
    func decodeServerError(
        data: Data,
        response: HTTPURLResponse,
        decoder: JSONDecoder
    ) -> (any Error)? {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let payload = json as? [String: Any],
              let reason = reason(from: payload) else {
            return nil
        }

        switch reason {
        case EmailFetchError.emailNotFound.code:
            return EmailFetchError.emailNotFound
        case EmailFetchError.emailMismatch.code:
            return EmailFetchError.emailMismatch
        default:
            return nil
        }
    }

    private func reason(from payload: [String: Any]) -> String? {
        if let reason = payload["reason"] as? String {
            return reason
        }

        if let details = payload["details"] as? [String: Any],
           let reason = details["reason"] as? String {
            return reason
        }

        if let error = payload["error"] as? [String: Any],
           let reason = error["reason"] as? String {
            return reason
        }

        return nil
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
