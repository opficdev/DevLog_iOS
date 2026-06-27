//
//  FunctionAPIEndpoint.swift
//  DevLogInfra
//
//  Created by opfic on 6/26/26.
//

import Foundation

extension FunctionAPIEndpoint where Response == EmptyAPIResponse {
    static func requestTodoDeletion(_ id: String) -> Self {
        Self(method: .post, path: "/todos/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func undoTodoDeletion(_ id: String) -> Self {
        Self(method: .delete, path: "/todos/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func requestWebPageDeletion(_ id: String) -> Self {
        Self(method: .post, path: "/web-pages/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func undoWebPageDeletion(_ id: String) -> Self {
        Self(method: .delete, path: "/web-pages/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func requestPushNotificationDeletion(_ id: String) -> Self {
        Self(method: .post, path: "/push-notifications/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func undoPushNotificationDeletion(_ id: String) -> Self {
        Self(method: .delete, path: "/push-notifications/\(functionAPIPathSegment(id))/deletion-request")
    }

    static let revokeAppleAccessToken = Self(method: .delete, path: "/auth/apple/access-token")
    static let revokeGithubAccessToken = Self(method: .delete, path: "/auth/github/access-token")
}

extension FunctionAPIEndpoint where Response == FunctionAPIResponse {
    static let requestAppleCustomToken = Self(method: .post, path: "/auth/apple/custom-token")
    static let refreshAppleAccessToken = Self(method: .post, path: "/auth/apple/access-token")
    static let requestAppleRefreshToken = Self(method: .post, path: "/auth/apple/refresh-token")
    static let requestGithubTokens = Self(method: .post, path: "/auth/github/tokens")
}

private func functionAPIPathSegment(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}
