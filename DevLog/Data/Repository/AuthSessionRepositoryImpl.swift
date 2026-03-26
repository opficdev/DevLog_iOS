//
//  AuthSessionRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

final class AuthSessionRepositoryImpl: AuthSessionRepository {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    var signedInPublisher: AnyPublisher<Bool, Never> {
        authService.observeSignedIn()
    }
}
