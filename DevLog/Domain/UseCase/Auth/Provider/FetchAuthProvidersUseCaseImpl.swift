//
//  FetchAuthProvidersUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

final class FetchAuthProvidersUseCaseImpl: FetchAuthProvidersUseCase {
    private let repository: AuthDataRepository
    
    init(_ repository: AuthDataRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> (currentProvider: AuthProvider?, allProviders: [AuthProvider]) {
        async let currentProvider = try await repository.fetchCurrentProvider()
        async let allProviders = try await repository.fetchAllProviders()
        
        return try await (currentProvider, allProviders)
    }
}
