//
//  LinkAuthProviderUseCaseImpl.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/12/26.
//

public final class LinkAuthProviderUseCaseImpl: LinkAuthProviderUseCase {
    private let repository: AuthDataRepository
    
    init(_ repository: AuthDataRepository) {
        self.repository = repository
    }
    
    public func execute(_ provider: AuthProvider) async throws -> Bool {
        try await repository.linkProvider(provider)
    }
}
