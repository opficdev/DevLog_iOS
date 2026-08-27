//
//  RestoreDevelopmentRecordUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

import Foundation

public final class RestoreDevelopmentRecordUseCaseImpl: RestoreDevelopmentRecordUseCase {
    private let repository: DevelopmentRecordRepository
    private let goalRepository: DevelopmentGoalRepository
    private let idProvider: () -> String

    init(
        _ repository: DevelopmentRecordRepository,
        _ goalRepository: DevelopmentGoalRepository,
        idProvider: @escaping () -> String = { UUID().uuidString }
    ) {
        self.repository = repository
        self.goalRepository = goalRepository
        self.idProvider = idProvider
    }

    public func execute(
        goalID: String,
        recordID: String,
        sourceVersionID: String
    ) async throws -> DevelopmentRecord.Version {
        let goal = try await goalRepository.fetchGoal(goalID)
        guard goal.status == .inProgress else {
            throw DomainLayerError.developmentGoalIsNotInProgress
        }

        let record = try await repository.fetchRecord(goalID: goalID, recordID: recordID)
        guard record.id == recordID, record.goalID == goalID else {
            throw DomainLayerError.invalidData(context: "developmentRecord")
        }
        guard record.draft == nil else {
            throw DomainLayerError.developmentRecordDraftConflict
        }
        guard let currentVersion = record.currentVersion else {
            throw DomainLayerError.developmentRecordVersionNotFound
        }

        let versions = try await repository.fetchVersions(goalID: goalID, recordID: recordID)
        guard versions.contains(where: {
            $0.id == sourceVersionID
                && $0.recordID == recordID
                && $0.number < currentVersion.number
        }) else {
            throw DomainLayerError.developmentRecordVersionNotFound
        }

        return try await repository.restoreVersion(
            goalID: goalID,
            recordID: recordID,
            versionID: idProvider(),
            sourceVersionID: sourceVersionID
        )
    }
}
