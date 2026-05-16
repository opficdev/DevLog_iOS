//
//  AuthenticationRepositoryImpl.swift
//  DevLogData
//
//  Created by 최윤진 on 11/2/25.
//

import DevLogDomain

final class AuthenticationRepositoryImpl: AuthenticationRepository {
    private let authService: AuthService
    private let appleAuthService: AuthenticationService
    private let githubAuthService: AuthenticationService
    private let googleAuthService: AuthenticationService
    private let userService: UserService
    private let widgetSnapshotUpdater: WidgetSnapshotUpdater

    init(
        authService: AuthService,
        appleAuthService: AuthenticationService,
        githubAuthService: AuthenticationService,
        googleAuthService: AuthenticationService,
        userService: UserService,
        widgetSnapshotUpdater: WidgetSnapshotUpdater
    ) {
        self.authService = authService
        self.appleAuthService = appleAuthService
        self.githubAuthService = githubAuthService
        self.googleAuthService = googleAuthService
        self.userService = userService
        self.widgetSnapshotUpdater = widgetSnapshotUpdater
    }

    func signIn(_ provider: AuthProvider) async throws {
        authService.beginSignIn()

        do {
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
            authService.completeSignIn()
        } catch {
            if authService.uid != nil {
                try? await authService.clearCurrentSession()
            }

            authService.cancelSignIn()
            throw mapSignInError(error)
        }
    }

    func signOut() async throws {
        guard let uid = authService.uid,
              let providerID = try await authService.getProviderID(),
              let provider = AuthProvider(rawValue: providerID)
        else {
            try await authService.clearCurrentSession()
            widgetSnapshotUpdater.clear()
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

        widgetSnapshotUpdater.clear()
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
        widgetSnapshotUpdater.clear()
    }
}

private extension AuthenticationRepositoryImpl {
    func mapSignInError(_ error: Error) -> Error {
        if let emailFetchError = error as? EmailFetchError,
           emailFetchError == .emailNotFound {
            return AuthError.emailNotFound
        }

        return error
    }
}
