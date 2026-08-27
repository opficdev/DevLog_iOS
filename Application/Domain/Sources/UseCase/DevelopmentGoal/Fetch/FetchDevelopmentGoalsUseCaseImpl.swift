//
//  FetchDevelopmentGoalsUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public final class FetchDevelopmentGoalsUseCaseImpl: FetchDevelopmentGoalsUseCase {
    private let repository: DevelopmentGoalRepository

    init(_ repository: DevelopmentGoalRepository) {
        self.repository = repository
    }

    public func execute(_ query: DevelopmentGoal.Query) async throws -> [DevelopmentGoal] {
        let goals = try await repository.fetchGoals(query)

        return goals
            .filter { query.status == nil || $0.status == query.status }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id < rhs.id
                }
                return lhs.createdAt < rhs.createdAt
            }
    }
}
