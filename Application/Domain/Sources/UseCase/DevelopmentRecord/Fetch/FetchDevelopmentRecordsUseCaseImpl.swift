//
//  FetchDevelopmentRecordsUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public final class FetchDevelopmentRecordsUseCaseImpl: FetchDevelopmentRecordsUseCase {
    private let repository: DevelopmentRecordRepository

    init(_ repository: DevelopmentRecordRepository) {
        self.repository = repository
    }

    public func execute(goalId: String) async throws -> [DevelopmentRecord] {
        try await repository.fetchRecords(goalId: goalId)
    }
}
