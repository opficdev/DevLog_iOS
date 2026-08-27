//
//  CreateDevelopmentRecordUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

import Foundation

public final class CreateDevelopmentRecordUseCaseImpl: CreateDevelopmentRecordUseCase {
    private let repository: DevelopmentRecordRepository
    private let goalRepository: DevelopmentGoalRepository
    private let idProvider: () -> String
    private let now: () -> Date

    init(
        _ repository: DevelopmentRecordRepository,
        _ goalRepository: DevelopmentGoalRepository,
        idProvider: @escaping () -> String = { UUID().uuidString },
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.goalRepository = goalRepository
        self.idProvider = idProvider
        self.now = now
    }

    public func execute(
        goalId: String,
        title: String,
        markdownContent: String
    ) async throws -> DevelopmentRecord {
        let goal = try await goalRepository.fetchGoal(goalId)
        guard goal.status == .inProgress else {
            throw DomainLayerError.developmentGoalIsNotInProgress
        }

        let draft = try DevelopmentRecord.Draft(
            title: title,
            markdownContent: markdownContent,
            baseVersionId: nil,
            updatedAt: now()
        )
        return try await repository.createRecord(
            id: idProvider(),
            goalId: goalId,
            draft: draft
        )
    }
}
