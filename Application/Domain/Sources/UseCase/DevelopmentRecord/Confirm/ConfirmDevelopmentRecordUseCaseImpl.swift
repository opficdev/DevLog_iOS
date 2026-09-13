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
        baseVersionId: String?
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
              draft.baseVersionId == baseVersionId else {
            throw DomainLayerError.developmentRecordDraftConflict
        }

        if let baseVersionId {
            return try await repository.confirmDraft(
                goalId: goalId,
                recordId: recordId,
                versionId: idProvider(),
                kind: .correction,
                sourceVersionId: baseVersionId
            )
        }

        return try await repository.confirmDraft(
            goalId: goalId,
            recordId: recordId,
            versionId: idProvider(),
            kind: .initial,
            sourceVersionId: nil
        )
    }
}
