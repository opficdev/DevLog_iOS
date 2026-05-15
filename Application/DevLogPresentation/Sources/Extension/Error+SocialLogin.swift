//
//  Error+SocialLogin.swift
//  DevLog
//
//  Created by opfic on 5/15/26.
//

import AuthenticationServices
import Foundation

extension Error {
    var isSocialLoginCancelled: Bool {
        switch self {
        case let authError as ASAuthorizationError:
            return authError.code == .canceled
        case let webAuthError as ASWebAuthenticationSessionError:
            return webAuthError.code == .canceledLogin
        default:
            let nsError = self as NSError
            return nsError.domain == "com.google.GIDSignIn" && nsError.code == -5
        }
    }
}
