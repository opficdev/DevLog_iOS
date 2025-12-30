//
//  RestoreAuthUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/30/25.
//

final class RestoreAuthUseCaseImpl: RestoreAuthUseCase {
    let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() -> Bool {
        return repository.restore()
    }
}
