//
//  AppleAuthResponse.swift
//  DevLog
//
//  Created by opfic on 5/16/25.
//

import Foundation
import AuthenticationServices

public struct AppleAuthResponse {
    public let nonce: String
    public let credential: ASAuthorizationAppleIDCredential
    public let authorizationCode: Data
    public let idTokenString: String
}
