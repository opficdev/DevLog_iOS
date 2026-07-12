//
//  AuthDataResponse.swift
//  Data
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation
import Domain

public struct AuthDataResponse {
    public let uid: String
    public let displayName: String?
    public let email: String?
    public let providers: [String]
    public let providerID: String
    public let fcmToken: String?

    public init(
        uid: String,
        displayName: String?,
        email: String?,
        providers: [String],
        providerID: String,
        fcmToken: String? = nil
    ) {
        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.providers = providers
        self.providerID = providerID
        self.fcmToken = fcmToken
    }
}
