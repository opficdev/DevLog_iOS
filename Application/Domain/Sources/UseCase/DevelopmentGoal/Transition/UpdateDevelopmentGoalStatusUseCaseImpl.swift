//
//  UpdateDevelopmentGoalStatusUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public final class UpdateDevelopmentGoalStatusUseCaseImpl: UpdateDevelopmentGoalStatusUseCase {
    private let repository: DevelopmentGoalRepository

    init(_ repository: DevelopmentGoalRepository) {
        self.repository = repository
    }

    public func execute(_ goalID: String, to status: DevelopmentGoal.Status) async throws {
        let goal = try await repository.fetchGoal(goalID)
        try goal.validateTransition(to: status)

        let snapshot: DevelopmentGoal.CompletionSnapshot?
        if status == .completed {
            let completionSnapshot = try await repository.fetchCompletionSnapshot(for: goalID)
            try completionSnapshot.goal.validateTransition(to: status)
            try validate(completionSnapshot, for: goal)
            snapshot = completionSnapshot
        } else {
            snapshot = nil
        }

        try await repository.transitionGoalStatus(
            goalID,
            to: status,
            completionSnapshot: snapshot
        )
    }
}

private extension UpdateDevelopmentGoalStatusUseCaseImpl {
    func validate(
        _ snapshot: DevelopmentGoal.CompletionSnapshot,
        for goal: DevelopmentGoal
    ) throws {
        guard snapshot.goal.id == goal.id,
              snapshot.records.allSatisfy({ $0.goalID == goal.id }) else {
            throw DomainLayerError.invalidData(context: "developmentGoalCompletionSnapshot")
        }
        guard !snapshot.records.isEmpty else {
            throw DomainLayerError.developmentGoalCompletionRequiresRecord
        }

        let lastRecord = snapshot.records.max { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id < rhs.id
            }
            return lhs.createdAt < rhs.createdAt
        }
        guard lastRecord?.currentVersion != nil else {
            throw DomainLayerError.developmentGoalCompletionNeedsVersion
        }
        guard !snapshot.records.contains(where: { $0.draft != nil }) else {
            throw DomainLayerError.developmentGoalCompletionHasDraft
        }
    }
}
