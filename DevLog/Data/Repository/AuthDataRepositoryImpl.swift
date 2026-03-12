//
//  AuthDataRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

import FirebaseAuth

final class AuthDataRepositoryImpl: AuthDataRepository {
    private let authService: AuthService
    private let appleAuthService: AuthenticationService
    private let githubAuthService: AuthenticationService
    private let googleAuthService: AuthenticationService
    
    init(
        authService: AuthService,
        appleAuthService: AuthenticationService,
        githubAuthService: AuthenticationService,
        googleAuthService: AuthenticationService
    ) {
        self.authService = authService
        self.appleAuthService = appleAuthService
        self.githubAuthService = githubAuthService
        self.googleAuthService = googleAuthService
    }
    
    func fetchCurrentProvider() async throws -> AuthProvider? {
        guard let providerString = try await authService.getProviderID() else {
            return nil
        }
        return AuthProvider(rawValue: providerString)
    }
    
    func fetchAllProviders() async throws -> [AuthProvider] {
        let providerStrings = authService.providerIDs
        return providerStrings.compactMap { AuthProvider(rawValue: $0) }
    }
    
    func linkProvider(_ provider: AuthProvider) async throws {
        guard let uid = authService.uid,
              let user = Auth.auth().currentUser,
              let email = user.email else {
            throw AuthError.notAuthenticated
        }
        
        let service: AuthenticationService
        switch provider {
        case .apple:
            service = appleAuthService
        case .google:
            service = googleAuthService
        case .github:
            service = githubAuthService
        }

        do {
            try await service.link(uid: uid, email: email)
        } catch {
            throw mapLinkError(error)
        }
    }
    
    func unlinkProvider(_ provider: AuthProvider) async throws {
        guard let uid = authService.uid,
              let user = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }

        if user.providerData.count <= 1 {
            throw AuthError.failedToUnlinkLastProvider
        }
        
        let service: AuthenticationService
        switch provider {
        case .apple:
            service = appleAuthService
        case .google:
            service = googleAuthService
        case .github:
            service = githubAuthService
        }
        
        try await service.unlink(uid)
    }
}

private extension AuthDataRepositoryImpl {
    func mapLinkError(_ error: Error) -> Error {
        if let emailFetchError = error as? EmailFetchError {
            switch emailFetchError {
            case .emailNotFound:
                return AuthError.linkEmailNotFound
            case .emailMismatch:
                return AuthError.linkEmailMismatch
            }
        }

        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain,
           let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
            switch authErrorCode {
            case .credentialAlreadyInUse:
                return AuthError.linkCredentialAlreadyInUse
            default:
                break
            }
        }

        return error
    }
}
