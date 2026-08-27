//
//  UpdateDevelopmentGoalStatusUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol UpdateDevelopmentGoalStatusUseCase {
    func execute(_ goalID: String, to status: DevelopmentGoal.Status) async throws
}
