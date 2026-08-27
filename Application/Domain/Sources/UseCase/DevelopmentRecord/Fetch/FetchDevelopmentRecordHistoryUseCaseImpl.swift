//
//  FetchDevelopmentRecordHistoryUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public final class FetchDevelopmentRecordHistoryUseCaseImpl: FetchDevelopmentRecordHistoryUseCase {
    private let repository: DevelopmentRecordRepository

    init(_ repository: DevelopmentRecordRepository) {
        self.repository = repository
    }

    public func execute(
        goalId: String,
        recordId: String
    ) async throws -> [DevelopmentRecord.Version] {
        try await repository.fetchVersions(goalId: goalId, recordId: recordId)
    }
}
