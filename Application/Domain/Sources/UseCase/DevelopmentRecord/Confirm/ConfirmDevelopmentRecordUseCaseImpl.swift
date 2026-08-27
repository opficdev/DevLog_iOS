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

    public func execute(goalID: String, recordID: String) async throws -> DevelopmentRecord.Version {
        let goal = try await goalRepository.fetchGoal(goalID)
        guard goal.status == .inProgress else {
            throw DomainLayerError.developmentGoalIsNotInProgress
        }

        let record = try await repository.fetchRecord(goalID: goalID, recordID: recordID)
        guard record.id == recordID, record.goalID == goalID else {
            throw DomainLayerError.invalidData(context: "developmentRecord")
        }
        guard record.draft != nil else {
            throw DomainLayerError.developmentRecordDraftNotFound
        }

        if let currentVersion = record.currentVersion {
            return try await repository.confirmDraft(
                goalID: goalID,
                recordID: recordID,
                versionID: idProvider(),
                kind: .correction,
                sourceVersionID: currentVersion.id
            )
        }

        return try await repository.confirmDraft(
            goalID: goalID,
            recordID: recordID,
            versionID: idProvider(),
            kind: .initial,
            sourceVersionID: nil
        )
    }
}
