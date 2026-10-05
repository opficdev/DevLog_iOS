//
//  FetchRecentDevelopmentRecordUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 10/5/26.
//

public final class FetchRecentDevelopmentRecordUseCaseImpl: FetchRecentDevelopmentRecordUseCase {
    private let repository: DevelopmentRecordRepository

    init(_ repository: DevelopmentRecordRepository) {
        self.repository = repository
    }

    public func execute(goalId: String) async throws -> DevelopmentRecord.Version? {
        let records = try await repository.fetchRecords(goalId: goalId)
        var versions = [DevelopmentRecord.Version]()

        try await withThrowingTaskGroup(of: DevelopmentRecord.Version.self) { group in
            for record in records {
                guard let currentVersion = record.currentVersion else { continue }
                group.addTask { [repository] in
                    try await repository.fetchVersion(
                        goalId: goalId,
                        recordId: record.id,
                        versionId: currentVersion.id
                    )
                }
            }

            for try await version in group {
                versions.append(version)
            }
        }

        return versions.max { $0.confirmedAt < $1.confirmedAt }
    }
}
