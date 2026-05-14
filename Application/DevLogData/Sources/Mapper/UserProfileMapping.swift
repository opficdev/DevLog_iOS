//
//  UserProfileMapping.swift
//  DevLog
//
//  Created by 최윤진 on 2/19/26.
//

import DevLogDomain
import DevLogDataDTO

public extension UserProfileResponse {
    public func toDomain() -> UserProfile {
        UserProfile(
            name: self.name,
            email: self.email,
            statusMessage: self.statusMessage,
            avatarURL: self.avatarURL,
            createdAt: self.createdAt
        )
    }
}
