//
//  AuthSessionRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

final class AuthSessionRepositoryImpl: AuthSessionRepository {
    @Published private var signIn: Bool = false

    var signedInPublisher: AnyPublisher<Bool, Never> {
        $signIn.eraseToAnyPublisher()
    }

    func setSession(_ signedIn: Bool) {
        self.signIn = signedIn
    }
}
