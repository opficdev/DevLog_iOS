//
//  UpdateTodoGoalUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol UpdateTodoGoalUseCase {
    func execute(todoID: String, goalID: String?) async throws
}
