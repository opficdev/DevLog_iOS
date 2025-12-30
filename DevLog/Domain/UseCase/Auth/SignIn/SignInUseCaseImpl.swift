//
//  SignInUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/30/25.
//

final class SignInUseCaseImpl: SignInUseCase {
    let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute(_ provider: AuthProvider) async throws {
        return try await repository.signIn(provider)
    }
}
