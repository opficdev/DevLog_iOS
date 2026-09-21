//
//  DevelopmentGoalItem.swift
//  HomeTab
//
//  Created by opfic on 9/20/26.
//

import Domain

struct DevelopmentGoalItem: Equatable, Identifiable {
    let goal: DevelopmentGoal
    let recentRecord: DevelopmentRecord.Version?
    let todoProgress: DevelopmentGoalTodoProgress

    var id: String { goal.id }

    init(
        goal: DevelopmentGoal,
        recentRecord: DevelopmentRecord.Version?,
        todoProgress: DevelopmentGoalTodoProgress = .empty
    ) {
        self.goal = goal
        self.recentRecord = recentRecord
        self.todoProgress = todoProgress
    }
}

struct DevelopmentGoalTodoProgress: Equatable {
    let completedCount: Int
    let totalCount: Int

    static let empty = Self(completedCount: 0, totalCount: 0)

    var fraction: Double {
        guard totalCount != 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var percentage: Int {
        guard totalCount != 0 else { return 0 }
        return (completedCount * 100 + totalCount / 2) / totalCount
    }

    var isEmpty: Bool {
        totalCount == 0
    }
}
