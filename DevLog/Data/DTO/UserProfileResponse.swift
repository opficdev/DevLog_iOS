//
//  UserProfileResponse.swift
//  DevLog
//
//  Created by 최윤진 on 1/10/26.
//

import Foundation

public struct UserProfileResponse: Decodable {
    public let name: String
    public let email: String
    public let statusMessage: String
    public let avatarURL: URL?
    public let createdAt: Date
}
