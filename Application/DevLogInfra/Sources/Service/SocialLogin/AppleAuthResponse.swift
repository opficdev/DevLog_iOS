//
//  AppleAuthResponse.swift
//  DevLog
//
//  Created by opfic on 5/16/25.
//

import Foundation
import AuthenticationServices

struct AppleAuthResponse {
    let nonce: String
    let credential: ASAuthorizationAppleIDCredential
    let authorizationCode: Data
    let idTokenString: String

    init(
        nonce: String,
        credential: ASAuthorizationAppleIDCredential,
        authorizationCode: Data,
        idTokenString: String
    ) {
        self.nonce = nonce
        self.credential = credential
        self.authorizationCode = authorizationCode
        self.idTokenString = idTokenString
    }
}
