//
//  DevelopmentGoalRepository.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol DevelopmentGoalRepository {
    func createGoal(
        id: String,
        title: String,
        markdownDescription: String
    ) async throws -> DevelopmentGoal
    func fetchGoal(_ goalID: String) async throws -> DevelopmentGoal
    func fetchGoals(_ query: DevelopmentGoal.Query) async throws -> [DevelopmentGoal]
    func fetchCompletionSnapshot(for goalID: String) async throws -> DevelopmentGoal.CompletionSnapshot
    func transitionGoalStatus(
        _ goalID: String,
        to status: DevelopmentGoal.Status,
        completionSnapshot: DevelopmentGoal.CompletionSnapshot?
    ) async throws
}
