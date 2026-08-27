//
//  FetchDevelopmentGoalUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public final class FetchDevelopmentGoalUseCaseImpl: FetchDevelopmentGoalUseCase {
    private let repository: DevelopmentGoalRepository

    init(_ repository: DevelopmentGoalRepository) {
        self.repository = repository
    }

    public func execute(_ goalID: String) async throws -> DevelopmentGoal {
        try await repository.fetchGoal(goalID)
    }
}
