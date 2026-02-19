//
//  FirebaseAuthUser.swift
//  DevLog
//
//  Created by 최윤진 on 11/3/25.
//

import Foundation
import FirebaseAuth

extension FirebaseAuth.User {
    func toResponse(
        providerID: AuthProviderID,
        fcmToken: String,
        accessToken: String? = nil
    ) -> AuthDataResponse {
        return AuthDataResponse(
            uid: self.uid,
            displayName: self.displayName,
            email: self.email,
            providers: self.providerData.map { $0.providerID },
            providerID: providerID.rawValue,
            fcmToken: fcmToken,
            accessToken: accessToken
        )
    }
}
