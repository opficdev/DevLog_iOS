//
//  FunctionAPIEndpoint.swift
//  Infra
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

    // WebPage id는 이미 Firestore document id로 percent-encoded된 값
    // 여기서 다시 인코딩하면 Functions가 실제 문서 id와 다른 값을 받는다
    static func requestWebPageDeletion(_ id: String) -> Self {
        Self(method: .post, path: "/web-pages/\(id)/deletion-request")
    }

    static func undoWebPageDeletion(_ id: String) -> Self {
        Self(method: .delete, path: "/web-pages/\(id)/deletion-request")
    }

    static func requestPushNotificationDeletion(_ id: String) -> Self {
        Self(method: .post, path: "/push-notifications/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func undoPushNotificationDeletion(_ id: String) -> Self {
        Self(method: .delete, path: "/push-notifications/\(functionAPIPathSegment(id))/deletion-request")
    }

    static let revokeGithubAccessToken = Self(method: .delete, path: "/auth/github/access-token")
}

extension FunctionAPIEndpoint where Response == AppleChallengeResponse {
    static let requestAppleChallenge = Self(method: .post, path: "/auth/apple/challenges")
}

extension FunctionAPIEndpoint where Response == AppleCustomTokenResponse {
    static let requestAppleCustomToken = Self(method: .post, path: "/auth/apple/custom-token")
}

extension FunctionAPIEndpoint where Response == AppleOperationResponse {
    static let linkAppleAccount = Self(method: .put, path: "/auth/apple/account-link")
    static let unlinkAppleAccount = Self(method: .delete, path: "/auth/apple/account-link")
    static let revokeAppleAccessToken = Self(method: .delete, path: "/auth/apple/access-token")
}

extension FunctionAPIEndpoint where Response == GithubAuthenticationResponse {
    static let linkGithubProvider = Self(method: .post, path: "/auth/github/link")
    static let requestGithubTokens = Self(method: .post, path: "/auth/github/tokens")
}

private func functionAPIPathSegment(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}
