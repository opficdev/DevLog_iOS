//
//  SignInUseCaseImpl.swift
//  DevLogDomain
//
//  Created by 최윤진 on 12/30/25.
//

public final class SignInUseCaseImpl: SignInUseCase {
    private let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    public func execute(_ provider: AuthProvider) async throws {
        try await repository.signIn(provider)
    }
}
