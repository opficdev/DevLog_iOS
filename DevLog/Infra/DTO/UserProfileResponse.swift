//
//  UserProfileResponse.swift
//  DevLog
//
//  Created by 최윤진 on 1/10/26.
//

import Foundation

struct UserProfileResponse: Decodable {
    let name: String
    let email: String
    let statusMessage: String
    let avatarURL: URL?
}
