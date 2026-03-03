//
//  AuthSessionRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

final class AuthSessionRepositoryImpl: AuthSessionRepository {
    private let authService: AuthService
    private let userDefaultsStore: UserDefaultsStore

    init(authService: AuthService, userDefaultsStore: UserDefaultsStore) {
        self.authService = authService
        self.userDefaultsStore = userDefaultsStore
        self.signIn = authService.uid != nil
    }

    @Published private var signIn: Bool = false

    var signedInPublisher: AnyPublisher<Bool, Never> {
        $signIn.eraseToAnyPublisher()
    }

    func setSession(_ signedIn: Bool) {
        if !signedIn {
            userDefaultsStore.removeAll()
        }
        self.signIn = signedIn
    }
}
