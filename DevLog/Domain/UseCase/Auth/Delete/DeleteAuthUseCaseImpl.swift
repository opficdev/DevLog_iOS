//
//  DeleteAuthUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/30/25.
//

final class DeleteAuthUseCaseImpl: DeleteAuthUseCase {
    let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.delete()
    }
}
