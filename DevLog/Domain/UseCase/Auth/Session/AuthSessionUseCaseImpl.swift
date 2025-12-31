//
//  AuthSessionUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

final class AuthSessionUseCaseImpl: AuthSessionUseCase {
    let repository: AuthSessionRepository

    init(_ repository: AuthSessionRepository) {
        self.repository = repository
    }

    func execute(_ signIn: Bool) {
        repository.setSession(signIn)
    }
}
