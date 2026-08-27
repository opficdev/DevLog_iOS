//
//  DevelopmentGoalMapping.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

import Domain

public extension DevelopmentGoalQuery {
    static func fromDomain(_ query: DevelopmentGoal.Query) -> Self {
        Self(status: query.status?.storageValue)
    }
}

public extension DevelopmentGoalResponse {
    func toDomain() throws -> DevelopmentGoal {
        try DevelopmentGoal(
            id: id,
            title: title,
            description: markdownDescription,
            status: try .fromStorageValue(status),
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

public extension DevelopmentGoal.Status {
    var storageValue: String {
        switch self {
        case .inProgress:
            "inProgress"
        case .completed:
            "completed"
        case .archived:
            "archived"
        }
    }

    static func fromStorageValue(_ value: String) throws -> Self {
        switch value {
        case "inProgress":
            .inProgress
        case "completed":
            .completed
        case "archived":
            .archived
        default:
            throw DataLayerError.invalidData("DevelopmentGoalResponse.status: \(value)")
        }
    }
}
