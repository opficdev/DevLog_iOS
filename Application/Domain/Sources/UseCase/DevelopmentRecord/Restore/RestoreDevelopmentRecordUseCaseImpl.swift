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
        goalId: String,
        recordId: String,
        sourceVersionId: String
    ) async throws -> DevelopmentRecord.Version {
        let goal = try await goalRepository.fetchGoal(goalId)
        guard goal.status == .inProgress else {
            throw DomainLayerError.developmentGoalIsNotInProgress
        }

        let record = try await repository.fetchRecord(goalId: goalId, recordId: recordId)
        guard record.id == recordId, record.goalId == goalId else {
            throw DomainLayerError.invalidData(context: "developmentRecord")
        }
        guard record.draft == nil else {
            throw DomainLayerError.developmentRecordDraftConflict
        }
        guard let currentVersion = record.currentVersion else {
            throw DomainLayerError.developmentRecordVersionNotFound
        }

        let versions = try await repository.fetchVersions(goalId: goalId, recordId: recordId)
        guard versions.contains(where: {
            $0.id == sourceVersionId
                && $0.recordId == recordId
                && $0.number < currentVersion.number
        }) else {
            throw DomainLayerError.developmentRecordVersionNotFound
        }

        return try await repository.restoreVersion(
            goalId: goalId,
            recordId: recordId,
            versionId: idProvider(),
            sourceVersionId: sourceVersionId
        )
    }
}
