//
//  SignInWithAppleUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

final class SignInWithAppleUseCaseImpl: SignInUseCase {
    let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async throws -> AuthenticationData {
        try await repository.signInWithApple()
    }
}
