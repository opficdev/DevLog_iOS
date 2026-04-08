//
//  InfraLayerError.swift
//  DevLog
//
//  Created by opfic on 3/11/26.
//

import AuthenticationServices
import Foundation
import GoogleSignIn

enum FirestoreError: Error, LocalizedError {
    case dataNotFound(_ key: String)

    var errorDescription: String? {
        switch self {
        case .dataNotFound(let key):
            return "\(key)가 Firestore에서 존재하지 않음"
        }
    }
}

enum UIError: Error {
    case notFoundTopViewController
}

enum EmailFetchError: Error, Equatable {
    case emailNotFound
    case emailMismatch

    var code: String {
        switch self {
        case .emailMismatch:
            "email_mismatch"
        case .emailNotFound:
            "email_not_found"
        }
    }
}

enum SocialLoginError: Error {
    case invalidOAuthState
    case failedToStartWebAuthenticationSession
}

extension Error {
    var isSocialLoginCancelled: Bool {
        switch self {
        // Apple 로그인 취소
        case let authError as ASAuthorizationError:
            return authError.code == .canceled
        // Github 로그인 취소
        case let webAuthError as ASWebAuthenticationSessionError:
            return webAuthError.code == .canceledLogin
        default:
            let nsError = self as NSError
            // Google 로그인 취소
            return nsError.domain == kGIDSignInErrorDomain && nsError.code == GIDSignInError.canceled.rawValue
        }
    }
}
