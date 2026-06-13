//
//  FirebaseAuthUser+.swift
//  DevLogInfra
//
//  Created by 최윤진 on 11/3/25.
//

import Foundation
import FirebaseAuth
import DevLogData

extension FirebaseAuth.User {
    func makeResponse(
        providerID: AuthProviderID,
        accessToken: String? = nil
    ) -> AuthDataResponse {
        return AuthDataResponse(
            uid: self.uid,
            displayName: self.displayName,
            email: self.email,
            providers: self.providerData.map { $0.providerID },
            providerID: providerID.rawValue,
            accessToken: accessToken
        )
    }
}

extension Error {
    var isFirebaseCredentialAlreadyInUse: Bool {
        let nsError = self as NSError
        guard nsError.domain == AuthErrorDomain,
              let authErrorCode = AuthErrorCode(rawValue: nsError.code) else {
            return false
        }
        return authErrorCode == .credentialAlreadyInUse
    }
}
