//
//  UpsertStatusMessageUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 1/10/26.
//

final class UpsertStatusMessageUseCaseImpl: UpsertStatusMessageUseCase {
    private let repository: UserDataRepository

    init(_ repository: UserDataRepository) {
        self.repository = repository
    }

    func execute(_ message: String) async throws {
        try await repository.upsertStatusMessage(message)
    }
}
