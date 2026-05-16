//
//  UserDataRepositoryImpl.swift
//  DevLogData
//
//  Created by 최윤진 on 1/10/26.
//

import DevLogDomain

final class UserDataRepositoryImpl: UserDataRepository {
    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    func fetch() async throws -> UserProfile {
        let response = try await userService.fetchUserProfile()

        return response.toDomain()
    }

    func upsertStatusMessage(_ message: String) async throws {
        try await userService.upsertStatusMessage(message)
    }
}
