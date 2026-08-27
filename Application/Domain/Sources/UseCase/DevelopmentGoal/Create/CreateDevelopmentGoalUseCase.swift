//
//  CreateDevelopmentGoalUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol CreateDevelopmentGoalUseCase {
    func execute(title: String, markdownDescription: String) async throws -> DevelopmentGoal
}
