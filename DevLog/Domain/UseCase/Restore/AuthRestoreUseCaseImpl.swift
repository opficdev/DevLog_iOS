//
//  AuthRestoreUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/30/25.
//

final class AuthRestoreUseCaseImpl: AuthRestoreUseCase {
    let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() -> Bool {
        return repository.restore()
    }
}
