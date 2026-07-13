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
        let proof = OAuthWebAuthenticationProof()
        let response = try await FunctionAPIClient.shared.send(
            endpoint,
            payload: OAuthAuthenticationSessionRequest(
                appChallenge: proof.appChallenge
            ),
            requiresAuthentication: requiresAuthentication
        )
        let callbackURL = try await OAuthWebAuthenticationSession.authenticate(
            url: response.authorizationURL,
            callbackURLScheme: OAuthWebAuthenticationProof.callbackURLScheme
        )

        return OAuthAuthenticationTicketRequest(
            ticket: try proof.ticket(from: callbackURL),
            appVerifier: proof.appVerifier
        )
    }
}
