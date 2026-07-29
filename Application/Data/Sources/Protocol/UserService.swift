//
//  UserService.swift
//  Data
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol UserService {
    func upsertUser(_ response: AuthDataResponse) async throws
    func fetchUserProfile() async throws -> UserProfileResponse
    func upsertStatusMessage(_ message: String) async throws
    func updateFCMToken(_ update: FCMTokenUpdate) async throws
    func updateUserTimeZone() async throws
}
