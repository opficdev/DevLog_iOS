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

    public func execute(goalId: String, recordId: String) async throws -> DevelopmentRecord.Version {
        let goal = try await goalRepository.fetchGoal(goalId)
        guard goal.status == .inProgress else {
            throw DomainLayerError.developmentGoalIsNotInProgress
        }

        let record = try await repository.fetchRecord(goalId: goalId, recordId: recordId)
        guard record.id == recordId, record.goalId == goalId else {
            throw DomainLayerError.invalidData(context: "developmentRecord")
        }
        guard record.draft != nil else {
            throw DomainLayerError.developmentRecordDraftNotFound
        }

        if let currentVersion = record.currentVersion {
            return try await repository.confirmDraft(
                goalId: goalId,
                recordId: recordId,
                versionId: idProvider(),
                kind: .correction,
                sourceVersionId: currentVersion.id
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
