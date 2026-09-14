//
//  RestoreDevelopmentRecordUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public final class RestoreDevelopmentRecordUseCaseImpl: RestoreDevelopmentRecordUseCase {
    private let repository: DevelopmentRecordRepository
    private let goalRepository: DevelopmentGoalRepository

    init(
        _ repository: DevelopmentRecordRepository,
        _ goalRepository: DevelopmentGoalRepository
    ) {
        self.repository = repository
        self.goalRepository = goalRepository
    }

    public func execute(
        goalId: String,
        recordId: String,
        versionId: String,
        sourceVersionId: String
    ) async throws -> DevelopmentRecord.Version {
        let record = try await repository.fetchRecord(goalId: goalId, recordId: recordId)
        if record.currentVersion?.id == versionId {
            return try await restoredVersion(
                record: record,
                goalId: goalId,
                recordId: recordId,
                versionId: versionId,
                sourceVersionId: sourceVersionId
            )
        }

        let goal = try await goalRepository.fetchGoal(goalId)
        guard goal.status == .inProgress else {
            throw DomainLayerError.developmentGoalIsNotInProgress
        }
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

        do {
            return try await repository.restoreVersion(
                goalId: goalId,
                recordId: recordId,
                versionId: versionId,
                sourceVersionId: sourceVersionId
            )
        } catch {
            guard let record = try? await repository.fetchRecord(
                goalId: goalId,
                recordId: recordId
            ), let version = try? await restoredVersion(
                record: record,
                goalId: goalId,
                recordId: recordId,
                versionId: versionId,
                sourceVersionId: sourceVersionId
            ) else {
                throw error
            }
            return version
        }
    }
}

private extension RestoreDevelopmentRecordUseCaseImpl {
    func restoredVersion(
        record: DevelopmentRecord,
        goalId: String,
        recordId: String,
        versionId: String,
        sourceVersionId: String
    ) async throws -> DevelopmentRecord.Version {
        guard record.currentVersion?.id == versionId else {
            throw DomainLayerError.developmentRecordVersionNotFound
        }
        let version = try await repository.fetchVersion(
            goalId: goalId,
            recordId: recordId,
            versionId: versionId
        )
        guard version.recordId == recordId,
              version.kind == .rollback,
              version.sourceVersionId == sourceVersionId else {
            throw DomainLayerError.developmentRecordVersionNotFound
        }
        return version
    }
}
