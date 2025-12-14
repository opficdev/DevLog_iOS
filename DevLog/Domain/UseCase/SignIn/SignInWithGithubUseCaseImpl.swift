//
//  SignInWithGithubUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/14/25.
//

import Foundation

final class SignInWithGithubUseCaseImpl: SignInUseCase {
    let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async throws -> AuthenticationData {
        try await repository.signInWithGithub()
    }
}
