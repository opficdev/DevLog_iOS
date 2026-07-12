//
//  OAuthWebAuthenticationSession.swift
//  Infra
//
//  Created by opfic on 7/12/26.
//

import AuthenticationServices
import Foundation

@MainActor
final class OAuthWebAuthenticationSession: NSObject {
    private let provider = TopViewControllerProvider()
    private var session: ASWebAuthenticationSession?

    static func authenticate(
        url: URL,
        callbackURLScheme: String
    ) async throws -> URL {
        let authenticationSession = OAuthWebAuthenticationSession()
        return try await authenticationSession.authenticate(
            url: url,
            callbackURLScheme: callbackURLScheme
        )
    }

    private func authenticate(
        url: URL,
        callbackURLScheme: String
    ) async throws -> URL {
        defer { session = nil }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: SocialLoginError.invalidOAuthCallback)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            self.session = session
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            if !session.start() {
                self.session = nil
                continuation.resume(
                    throwing: SocialLoginError.failedToStartWebAuthenticationSession
                )
            }
        }
    }
}

extension OAuthWebAuthenticationSession: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        provider.keyWindow() ?? ASPresentationAnchor()
    }
}
