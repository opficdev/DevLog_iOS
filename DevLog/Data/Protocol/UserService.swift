//
//  UserService.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation
import DevLogDomain
import DevLogDataDTO

public protocol UserService {
    func upsertUser(_ response: AuthDataResponse) async throws
    func fetchUserProfile() async throws -> UserProfileResponse
    func upsertStatusMessage(_ message: String) async throws
    func updateFCMToken(_ fcmToken: String) async throws
    func updateUserTimeZone() async throws
}
