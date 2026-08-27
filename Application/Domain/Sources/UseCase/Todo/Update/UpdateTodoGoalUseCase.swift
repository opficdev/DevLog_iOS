//
//  UpdateTodoGoalUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol UpdateTodoGoalUseCase {
    func execute(todoId: String, goalId: String?) async throws
}
