//
//  AppleAuthResponse.swift
//  Infra
//
//  Created by opfic on 5/16/25.
//

import Foundation

struct AppleAuthResponse {
    let authorizationCode: String
    let fullName: PersonNameComponents?
    let email: String?
}
