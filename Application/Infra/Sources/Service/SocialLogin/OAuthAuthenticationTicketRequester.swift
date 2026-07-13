//
//  OAuthAuthenticationTicketRequester.swift
//  Infra
//
//  Created by opfic on 7/13/26.
//

enum OAuthAuthenticationTicketRequester {
    static func request(
        endpoint: FunctionAPIEndpoint<OAuthAuthenticationSessionResponse>,
        requiresAuthentication: Bool
    ) async throws -> OAuthAuthenticationTicketRequest {
        let handler = OAuthTicketExchangeHandler()
        let response = try await FunctionAPIClient.shared.send(
            endpoint,
            payload: OAuthAuthenticationSessionRequest(
                appChallenge: handler.appChallenge
            ),
            requiresAuthentication: requiresAuthentication
        )
        let callbackURL = try await OAuthWebAuthenticationSession.authenticate(
            url: response.authorizationURL,
            callbackURLScheme: OAuthTicketExchangeHandler.callbackURLScheme
        )

        return OAuthAuthenticationTicketRequest(
            ticket: try handler.ticket(from: callbackURL),
            appVerifier: handler.appVerifier
        )
    }
}
