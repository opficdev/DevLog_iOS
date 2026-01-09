//
//  AuthenticationData+.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation

struct AuthenticationDataResponse {
    let uid: String
    let displayName: String?
    let email: String?
    let providers: [String]
    let providerID: String
    let fcmToken: String
    let accessToken: String?

    init(
        uid: String,
        displayName: String?,
        email: String?,
        providers: [String],
        providerID: String,
        fcmToken: String,
        accessToken: String? = nil
    ) {
        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.providers = providers
        self.providerID = providerID
        self.fcmToken = fcmToken
        self.accessToken = accessToken
    }
}
