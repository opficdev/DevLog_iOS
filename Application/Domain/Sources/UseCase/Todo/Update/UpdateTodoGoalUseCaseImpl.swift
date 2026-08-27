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

    public func execute(todoID: String, goalID: String?) async throws {
        if let goalID {
            _ = try await goalRepository.fetchGoal(goalID)
        }

        var todo = try await todoRepository.fetchTodo(todoID)
        todo.goalID = goalID
        try await todoRepository.upsertTodo(todo)
    }
}
