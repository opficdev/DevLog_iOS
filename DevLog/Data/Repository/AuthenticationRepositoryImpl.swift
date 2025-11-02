//
//  AuthenticationRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation

final class AuthenticationRepositoryImpl {
    private let appleService: AppleSignInService
    private let githubService: GithubSignInService
    private let googleService: GoogleSignInService

    init(
        appleService: AppleSignInService,
        githubService: GithubSignInService,
        googleService: GoogleSignInService
    ) {
        self.appleService = appleService
        self.githubService = githubService
        self.googleService = googleService
    }

    func signInWithApple() async throws -> AuthenticationData {
        return try await appleService.signIn()
    }

    func signInWithGithub() async throws -> AuthenticationData {
        return try await githubService.signIn()
    }

    func signInWithGoogle() async throws -> AuthenticationData {
        return try await googleService.signIn()
    }
}
