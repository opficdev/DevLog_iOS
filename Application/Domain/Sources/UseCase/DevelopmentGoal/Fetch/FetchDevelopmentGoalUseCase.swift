//
//  FetchDevelopmentGoalUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol FetchDevelopmentGoalUseCase {
    func execute(_ goalID: String) async throws -> DevelopmentGoal
}
