//
//  SignOutUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/30/25.
//

final class SignOutUseCaseImpl: SignOutUseCase {
    private let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.signOut()
    }
}
