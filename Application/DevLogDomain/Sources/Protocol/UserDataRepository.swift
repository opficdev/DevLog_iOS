//
//  UserDataRepository.swift
//  DevLogDomain
//
//  Created by 최윤진 on 1/10/26.
//

public protocol UserDataRepository {
    func fetch() async throws -> UserProfile
    func upsertStatusMessage(_ message: String) async throws
}
