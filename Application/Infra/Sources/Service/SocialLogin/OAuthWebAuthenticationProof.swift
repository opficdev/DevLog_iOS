//
//  OAuthWebAuthenticationProof.swift
//  Infra
//
//  Created by opfic on 7/12/26.
//

import CryptoKit
import Foundation

struct OAuthWebAuthenticationProof {
    static let callbackURLScheme = "DevLog"

    let appVerifier: String
    let appChallenge: String

    init() {
        let verifier = Self.makeVerifier()
        appVerifier = verifier
        appChallenge = Self.challenge(for: verifier)
    }

    init(appVerifier: String) {
        self.appVerifier = appVerifier
        appChallenge = Self.challenge(for: appVerifier)
    }

    func ticket(from callbackURL: URL) throws -> String {
        guard callbackURL.scheme?.caseInsensitiveCompare(Self.callbackURLScheme) == .orderedSame,
              callbackURL.host == "oauth-callback",
              let components = URLComponents(
                url: callbackURL,
                resolvingAgainstBaseURL: false
              ),
              let ticket = components.queryItems?
                .first(where: { $0.name == "ticket" })?
                .value?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !ticket.isEmpty else {
            throw SocialLoginError.invalidOAuthCallback
        }

        return ticket
    }
}

private extension OAuthWebAuthenticationProof {
    static func makeVerifier() -> String {
        [UUID().uuidString, UUID().uuidString]
            .joined()
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
    }

    static func challenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
