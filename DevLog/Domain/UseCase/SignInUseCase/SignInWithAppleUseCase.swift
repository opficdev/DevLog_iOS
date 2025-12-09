//
//  SignInWithAppleUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation

final class SignInWithAppleUseCase: SignInUseCasing {
    let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async throws -> AuthenticationData {
        try await repository.signInWithApple()
    }
}
