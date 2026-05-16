//
//  AuthSessionRepositoryImpl.swift
//  DevLogData
//
//  Created by 최윤진 on 12/31/25.
//

import Combine
import DevLogDomain

final class AuthSessionRepositoryImpl: AuthSessionRepository {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        authService.observeSignedIn()
    }
}
