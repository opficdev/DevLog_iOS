//
//  FetchDevelopmentGoalsUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol FetchDevelopmentGoalsUseCase {
    func execute(_ query: DevelopmentGoal.Query) async throws -> [DevelopmentGoal]
}
