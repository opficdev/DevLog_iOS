//
//  DevelopmentGoalMapping.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

import Domain

public extension DevelopmentGoalQuery {
    static func fromDomain(_ query: DevelopmentGoal.Query) -> Self {
        Self(status: query.status.map(DevelopmentGoalStatus.fromDomain))
    }
}

public extension DevelopmentGoalResponse {
    func toDomain() throws -> DevelopmentGoal {
        try DevelopmentGoal(
            id: id,
            title: title,
            description: markdownDescription,
            status: status.toDomain(),
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt
        )
    }
}

public extension DevelopmentGoalCompletionResponse {
    func toDomain() throws -> DevelopmentGoal.CompletionSnapshot {
        try DevelopmentGoal.CompletionSnapshot(
            goal: goal.toDomain(),
            records: records.map { try $0.toDomain() }
        )
    }
}

public extension DevelopmentGoalStatus {
    static func fromDomain(_ status: DevelopmentGoal.Status) -> Self {
        switch status {
        case .inProgress:
            .inProgress
        case .completed:
            .completed
        case .archived:
            .archived
        }
    }

    func toDomain() -> DevelopmentGoal.Status {
        switch self {
        case .inProgress:
            .inProgress
        case .completed:
            .completed
        case .archived:
            .archived
        }
    }

}
