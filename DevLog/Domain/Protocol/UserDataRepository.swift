//
//  UserDataRepository.swift
//  DevLog
//
//  Created by 최윤진 on 1/10/26.
//

protocol UserDataRepository {
    func fetch() async throws -> UserProfile
    func upsertStatusMessage(_ message: String) async throws
    func updateFCMToken(_ fcmToken: String) async throws
    func updateUserTimeZone() async throws
}
