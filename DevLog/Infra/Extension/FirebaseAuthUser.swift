//
//  FirebaseAuthUser.swift
//  DevLog
//
//  Created by 최윤진 on 11/3/25.
//

import Foundation
import FirebaseAuth

extension FirebaseAuth.User {
    func toData(
        providerID: AuthProviderID,
        fcmToken: String,
        accessToken: String? = nil
    ) -> AuthenticationData {
        return AuthenticationData(
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
