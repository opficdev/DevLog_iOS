//
//  DevelopmentGoalDTO.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

import Foundation

public struct DevelopmentGoalCreateRequest: Encodable {
    public let title: String
    public let markdownDescription: String

    public init(title: String, markdownDescription: String) {
        self.title = title
        self.markdownDescription = markdownDescription
    }
}

public struct DevelopmentGoalQuery {
    public let status: String?

    public init(status: String?) {
        self.status = status
    }
}

public struct DevelopmentGoalStatusRequest {
    public let status: String

    public init(status: String) {
        self.status = status
    }
}

public struct DevelopmentGoalResponse {
    public let id: String
    public let title: String
    public let markdownDescription: String
    public let status: String
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?

    public init(
        id: String,
        title: String,
        markdownDescription: String,
        status: String,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.markdownDescription = markdownDescription
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }
}

public struct DevelopmentGoalCompletionResponse {
    public let goal: DevelopmentGoalResponse
    public let records: [DevelopmentRecordResponse]

    public init(goal: DevelopmentGoalResponse, records: [DevelopmentRecordResponse]) {
        self.goal = goal
        self.records = records
    }
}
