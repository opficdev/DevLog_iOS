//
//  SaveDevelopmentRecordDraftUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

import Foundation

public final class SaveDevelopmentRecordDraftUseCaseImpl: SaveDevelopmentRecordDraftUseCase {
    private let repository: DevelopmentRecordRepository
    private let goalRepository: DevelopmentGoalRepository
    private let now: () -> Date

    init(
        _ repository: DevelopmentRecordRepository,
        _ goalRepository: DevelopmentGoalRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.goalRepository = goalRepository
        self.now = now
    }

    public func execute(
        goalID: String,
        recordID: String,
        title: String,
        markdownContent: String
    ) async throws -> DevelopmentRecord {
        let goal = try await goalRepository.fetchGoal(goalID)
        guard goal.status == .inProgress else {
            throw DomainLayerError.developmentGoalIsNotInProgress
        }

        let record = try await repository.fetchRecord(goalID: goalID, recordID: recordID)
        guard record.id == recordID, record.goalID == goalID else {
            throw DomainLayerError.invalidData(context: "developmentRecord")
        }
        let updatedDraft = try DevelopmentRecord.Draft(
            title: title,
            markdownContent: markdownContent,
            baseVersionID: record.currentVersion?.id,
            updatedAt: now()
        )
        return try await repository.saveDraft(
            goalID: goalID,
            recordID: recordID,
            draft: updatedDraft
        )
    }
}
