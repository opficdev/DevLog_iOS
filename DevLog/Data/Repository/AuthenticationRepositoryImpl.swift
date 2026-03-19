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
    private let userService: UserService

    init(
        authService: AuthService,
        appleAuthService: AuthenticationService,
        githubAuthService: AuthenticationService,
        googleAuthService: AuthenticationService,
        userService: UserService
    ) {
        self.authService = authService
        self.appleAuthService = appleAuthService
        self.githubAuthService = githubAuthService
        self.googleAuthService = googleAuthService
        self.userService = userService
    }

    func signIn(_ provider: AuthProvider) async throws {
        let response: AuthDataResponse
        switch provider {
        case .apple:
            response = try await appleAuthService.signIn()
        case .github:
            response = try await githubAuthService.signIn()
        case .google:
            response = try await googleAuthService.signIn()
        }
        try await userService.upsertUser(response)
    }

    func signOut() async throws {
        guard let uid = authService.uid,
              let providerID = try await authService.getProviderID(),
              let provider = AuthProvider(rawValue: providerID)
        else {
            try await authService.clearCurrentSession()
            return
        }

        do {
            switch provider {
            case .apple:
                try await appleAuthService.signOut(uid)
            case .github:
                try await githubAuthService.signOut(uid)
            case .google:
                try await googleAuthService.signOut(uid)
            }
        } catch AuthError.notAuthenticated {
            try await authService.clearCurrentSession()
        }
    }

    func restore() -> Bool {
        // MARK: 후에 Google API를 사용 시 Google만의 restorePreviousSignIn 로직 추가
        return authService.uid != nil
    }

    func delete() async throws {
        guard let uid = authService.uid else {
            throw AuthError.notAuthenticated
        }

        let providers = authService.providerIDs.compactMap { AuthProvider(rawValue: $0) }

        for provider in providers {
            switch provider {
            case .apple:
                try await appleAuthService.deleteAuth(uid)
            case .github:
                try await githubAuthService.deleteAuth(uid)
            case .google:
                try await googleAuthService.deleteAuth(uid)
            }
        }

        try await authService.deleteCurrentUser()
        try await authService.clearCurrentSession()
    }
}
