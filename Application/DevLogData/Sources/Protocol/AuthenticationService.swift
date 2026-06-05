//
//  AuthenticationService.swift
//  DevLogData
//
//  Created by 최윤진 on 11/3/25.
//

import Foundation

public protocol AuthenticationService: Sendable {
    func signIn() async throws -> AuthDataResponse
    func signOut(_ uid: String) async throws
    func deleteAuth(_ uid: String) async throws
    func link(uid: String, email: String) async throws
    func unlink(_ uid: String) async throws
}
