//
//  FetchUserDataUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 1/10/26.
//

public final class FetchUserDataUseCaseImpl: FetchUserDataUseCase {
    private let repository: UserDataRepository

    init(_ repository: UserDataRepository) {
        self.repository = repository
    }

    public func execute() async throws -> UserProfile {
        return try await repository.fetch()
    }
}
