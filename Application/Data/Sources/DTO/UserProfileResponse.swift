//
//  UserProfileResponse.swift
//  Data
//
//  Created by 최윤진 on 1/10/26.
//

import Foundation
import Domain

public struct UserProfileResponse: Decodable {
    public let name: String
    public let email: String
    public let statusMessage: String
    public let avatarURL: URL?
    public let createdAt: Date

    public init(
        name: String,
        email: String,
        statusMessage: String,
        avatarURL: URL?,
        createdAt: Date
    ) {
        self.name = name
        self.email = email
        self.statusMessage = statusMessage
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}
