//
//  AuthenticationRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation

final class AuthenticationRepositoryImpl: AuthenticationRepository {
    private let appleAuthService: AuthenticationService
    private let githubAuthService: AuthenticationService
    private let googleAuthService: AuthenticationService

    init(
        appleAuthService: AuthenticationService,
        githubAuthService: AuthenticationService,
        googleAuthService: AuthenticationService
    ) {
        self.appleAuthService = appleAuthService
        self.githubAuthService = githubAuthService
        self.googleAuthService = googleAuthService
    }

    func signInWithApple() async throws -> AuthenticationData {
        return try await appleAuthService.signIn()
    }

    func signInWithGithub() async throws -> AuthenticationData {
        return try await githubAuthService.signIn()
    }

    func signInWithGoogle() async throws -> AuthenticationData {
        return try await googleAuthService.signIn()
    }
}
