//
//  UnlinkAuthProviderUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

final class UnlinkAuthProviderUseCaseImpl: UnlinkAuthProviderUseCase {
    private let repository: AuthDataRepository
    
    init(_ repository: AuthDataRepository) {
        self.repository = repository
    }
    
    func execute(_ provider: AuthProvider) async throws {
        try await repository.unlinkProvider(provider)
    }
}
