//
//  ConfirmDevelopmentRecordUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

import Foundation

public final class ConfirmDevelopmentRecordUseCaseImpl: ConfirmDevelopmentRecordUseCase {
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
        baseVersionId: String?,
        draftRevisionId: String?
    ) async throws -> DevelopmentRecord.Version {
        let goal = try await goalRepository.fetchGoal(goalId)
        guard goal.status == .inProgress else {
            throw DomainLayerError.developmentGoalIsNotInProgress
        }

        let record = try await repository.fetchRecord(goalId: goalId, recordId: recordId)
        guard record.id == recordId, record.goalId == goalId else {
            throw DomainLayerError.invalidData(context: "developmentRecord")
        }
        guard let draft = record.draft else {
            throw DomainLayerError.developmentRecordDraftNotFound
        }
        guard record.currentVersion?.id == baseVersionId,
              draft.baseVersionId == baseVersionId,
              draft.revisionId == draftRevisionId else {
            throw DomainLayerError.developmentRecordDraftConflict
        }

        let versionId = idProvider()
        let kind = baseVersionId == nil
            ? DevelopmentRecord.Version.Kind.initial
            : .correction
        do {
            return try await repository.confirmDraft(
                goalId: goalId,
                recordId: recordId,
                versionId: versionId,
                kind: kind,
                sourceVersionId: baseVersionId,
                draftRevisionId: draftRevisionId
            )
        } catch {
            guard let version = try? await confirmedVersion(
                goalId: goalId,
                recordId: recordId,
                versionId: versionId
            ) else {
                throw error
            }
            return version
        }
    }
}

private extension ConfirmDevelopmentRecordUseCaseImpl {
    func confirmedVersion(
        goalId: String,
        recordId: String,
        versionId: String
    ) async throws -> DevelopmentRecord.Version {
        let record = try await repository.fetchRecord(goalId: goalId, recordId: recordId)
        guard record.currentVersion?.id == versionId else {
            throw DomainLayerError.developmentRecordVersionNotFound
        }
        let versions = try await repository.fetchVersions(goalId: goalId, recordId: recordId)
        guard let version = versions.first(where: { $0.id == versionId }) else {
            throw DomainLayerError.developmentRecordVersionNotFound
        }
        return version
    }
}
