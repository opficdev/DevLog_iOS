//
//  SignInWithGoogleUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/14/25.
//

final class SignInWithGoogleUseCaseImpl: SignInUseCase {
    let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async throws -> AuthenticationData {
        try await repository.signInWithGoogle()
    }
}
