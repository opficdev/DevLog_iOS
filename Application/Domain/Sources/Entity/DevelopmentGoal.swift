//
//  DevelopmentGoal.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

import Foundation

public struct DevelopmentGoal: Hashable {
    public enum Status: Hashable {
        case inProgress
        case completed
        case archived
    }

    public struct Query: Hashable {
        public let status: Status?

        public init(status: Status? = nil) {
            self.status = status
        }
    }

    public struct CompletionSnapshot: Hashable {
        public let goal: DevelopmentGoal
        public let records: [DevelopmentRecord]

        public init(goal: DevelopmentGoal, records: [DevelopmentRecord]) {
            self.goal = goal
            self.records = records
        }
    }

    public let id: String
    public let title: String
    public let description: String
    public let status: Status
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?

    public init(
        id: String,
        title: String,
        description: String,
        status: Status,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date?
    ) throws {
        guard title.containsMeaningfulCharacter else {
            throw DomainLayerError.invalidDevelopmentGoalTitle
        }

        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    public func validateTransition(to status: Status) throws {
        let isAllowed: Bool
        switch (self.status, status) {
        case (.inProgress, .completed),
             (.inProgress, .archived),
             (.completed, .inProgress),
             (.archived, .inProgress):
            isAllowed = true
        default:
            isAllowed = false
        }

        guard isAllowed else {
            throw DomainLayerError.invalidDevelopmentGoalTransition
        }
    }
}

private extension String {
    var containsMeaningfulCharacter: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
