//
//  UserProfileMapping.swift
//  Data
//
//  Created by 최윤진 on 2/19/26.
//

import Domain

public extension UserProfileResponse {
    func toDomain() -> UserProfile {
        UserProfile(
            name: self.name,
            email: self.email,
            statusMessage: self.statusMessage,
            avatarURL: self.avatarURL,
            createdAt: self.createdAt
        )
    }
}
