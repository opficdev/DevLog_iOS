//
//  SignInWithGithubUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 11/14/25.
//

import Foundation

final class SignInWithGithubUseCase: SignInUseCasing {
    typealias Output = AuthenticationData
    let repository: AuthenticationRepository

    init(repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async throws -> AuthenticationData {
        try await repository.signInWithGithub()
    }
}
