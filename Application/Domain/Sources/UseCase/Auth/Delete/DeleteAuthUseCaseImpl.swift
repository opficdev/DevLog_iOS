//
//  DeleteAuthUseCaseImpl.swift
//  Domain
//
//  Created by 최윤진 on 12/30/25.
//

public final class DeleteAuthUseCaseImpl: DeleteAuthUseCase {
    private let repository: AuthenticationRepository

    init(_ repository: AuthenticationRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.delete()
    }
}
