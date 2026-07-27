//
//  InfraLayerError.swift
//  Infra
//
//  Created by opfic on 3/11/26.
//

import AuthenticationServices
import Foundation

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

enum SocialLoginError: Error {
    case invalidOAuthCallback
    case failedToStartWebAuthenticationSession
    case authenticationAlreadyInProgress
}

enum AppVersionServiceError: Error, Equatable {
    case missingLookupURL
    case invalidLookupURL
    case missingVersion
    case invalidVersion
}

extension Error {
    var isSocialLoginCancelled: Bool {
        switch self {
        case let authError as ASAuthorizationError:
            return authError.code == .canceled
        case let webAuthError as ASWebAuthenticationSessionError:
            return webAuthError.code == .canceledLogin
        default:
            let error = self as NSError
            return error.domain == "com.google.GIDSignIn" && error.code == -5
        }
    }
}
