//
//  AuthenticationRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

final class AuthenticationRepositoryImpl: AuthenticationRepository {
    private let authService: AuthService
    private let appleAuthService: AuthenticationService
    private let githubAuthService: AuthenticationService
    private let googleAuthService: AuthenticationService

    init(
        authService: AuthService = .shared,
        appleAuthService: AuthenticationService,
        githubAuthService: AuthenticationService,
        googleAuthService: AuthenticationService
    ) {
        self.authService = authService
        self.appleAuthService = appleAuthService
        self.githubAuthService = githubAuthService
        self.googleAuthService = googleAuthService
    }

    func signIn(_ provider: AuthProvider) async throws {
        switch provider {
        case .apple:
            _ = try await appleAuthService.signIn()
        case .github:
            _ = try await githubAuthService.signIn()
        case .google:
            _ = try await googleAuthService.signIn()
        }
    }

    func signOut() async throws {
        guard let uid = authService.uid,
              let providerID = try await authService.getProviderID(),
              let provider = AuthProvider(rawValue: providerID)
        else {
            throw AuthError.notAuthenticated
        }

        switch provider {
        case .apple:
            try await appleAuthService.signOut(uid)
        case .github:
            try await githubAuthService.signOut(uid)
        case .google:
            try await googleAuthService.signOut(uid)
        }
    }

    func restore() -> Bool {
        // MARK: 후에 Google API를 사용 시 Google만의 restorePreviousSignIn 로직 추가
        return authService.uid != nil
    }

    func delete() async throws {
        guard let uid = authService.uid,
              let providerID = try await authService.getProviderID(),
              let provider = AuthProvider(rawValue: providerID)
        else {
            throw AuthError.notAuthenticated
        }

        switch provider {
        case .apple:
            try await appleAuthService.deleteAuth(uid)
        case .github:
            try await githubAuthService.deleteAuth(uid)
        case .google:
            try await googleAuthService.deleteAuth(uid)
        }
    }
}
