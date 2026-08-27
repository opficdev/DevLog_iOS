//
//  UpdateTodoGoalUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public final class UpdateTodoGoalUseCaseImpl: UpdateTodoGoalUseCase {
    private let todoRepository: TodoRepository
    private let goalRepository: DevelopmentGoalRepository

    init(
        _ todoRepository: TodoRepository,
        _ goalRepository: DevelopmentGoalRepository
    ) {
        self.todoRepository = todoRepository
        self.goalRepository = goalRepository
    }

    public func execute(todoId: String, goalId: String?) async throws {
        if let goalId {
            _ = try await goalRepository.fetchGoal(goalId)
        }

        var todo = try await todoRepository.fetchTodo(todoId)
        todo.goalId = goalId
        try await todoRepository.upsertTodo(todo)
    }
}
