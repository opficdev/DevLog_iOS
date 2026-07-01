//
//  UnlinkAuthProviderUseCaseImpl.swift
//  Domain
//
//  Created by 최윤진 on 2/12/26.
//

public final class UnlinkAuthProviderUseCaseImpl: UnlinkAuthProviderUseCase {
    private let repository: AuthDataRepository
    
    init(_ repository: AuthDataRepository) {
        self.repository = repository
    }
    
    public func execute(_ provider: AuthProvider) async throws {
        try await repository.unlinkProvider(provider)
    }
}
