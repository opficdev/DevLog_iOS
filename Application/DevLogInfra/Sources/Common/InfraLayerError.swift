//
//  InfraLayerError.swift
//  DevLog
//
//  Created by opfic on 3/11/26.
//

import AuthenticationServices
import Foundation
import DevLogData

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

enum TokenError: Error {
    case invalidResponse
}

enum SocialLoginError: Error {
    case invalidOAuthState
    case failedToStartWebAuthenticationSession
    case authenticationAlreadyInProgress
}
