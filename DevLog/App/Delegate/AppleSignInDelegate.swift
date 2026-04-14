//
//  AppleSignInDelegate.swift
//  DevLog
//
//  Created by opfic on 4/17/25.
//

import Foundation
import AuthenticationServices

@MainActor
final class AppleSignInDelegate: NSObject,
                                 ASAuthorizationControllerDelegate,
                                 ASAuthorizationControllerPresentationContextProviding {
    private let finish: @MainActor (Result<ASAuthorization, Error>) -> Void

    init(finish: @escaping @MainActor (Result<ASAuthorization, Error>) -> Void) {
        self.finish = finish
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        finish(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        finish(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first { $0.isKeyWindow }!
    }
}
