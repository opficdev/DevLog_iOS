//
//  DevelopmentGoalListTestDoubles.swift
//  DevelopmentTabTests
//
//  Created by opfic on 10/5/26.
//

import Domain
import Foundation
import PresentationShared
@testable import DevelopmentTab

@MainActor
struct StoreTestAdapter {
    let goalsSpy: FetchDevelopmentGoalsUseCaseSpy
    let recentRecordSpy: FetchRecentDevelopmentRecordUseCaseSpy
    private let store: TestStoreOf<DevelopmentGoalListFeature>

    var state: DevelopmentGoalListFeature.State { store.state }

    init(
        goals: [DevelopmentGoal] = [],
        recentRecords records: [String: DevelopmentRecord.Version] = [:]
    ) {
        let goalsSpy = FetchDevelopmentGoalsUseCaseSpy(goals: goals)
        let recentRecordSpy = FetchRecentDevelopmentRecordUseCaseSpy(recentRecords: records)
        self.goalsSpy = goalsSpy
        self.recentRecordSpy = recentRecordSpy
        store = TestStore(initialState: DevelopmentGoalListFeature.State()) {
            DevelopmentGoalListFeature()
        } withDependencies: {
            DevelopmentTabDependencyPreparation.prepareGoalList(
                &$0,
                goalsUseCase: goalsSpy,
                recentRecordUseCase: recentRecordSpy
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func send(_ action: DevelopmentGoalListFeature.Action) async {
        await store.send(action)
    }

    func load(_ action: DevelopmentGoalListFeature.Action) async {
        await store.send(action)
        await settle()
    }

    func settle() async {
        await store.finish()
        await store.skipReceivedActions(strict: false)
    }
}

actor FetchDevelopmentGoalsUseCaseSpy: FetchDevelopmentGoalsUseCase {
    private var result: Result<[DevelopmentGoal], Error>

    init(goals: [DevelopmentGoal]) {
        result = .success(goals)
    }

    func setResult(_ result: Result<[DevelopmentGoal], Error>) {
        self.result = result
    }

    func execute(_ query: DevelopmentGoal.Query) async throws -> [DevelopmentGoal] {
        try result.get()
    }
}

actor FetchRecentDevelopmentRecordUseCaseSpy: FetchRecentDevelopmentRecordUseCase {
    private(set) var goalIDs = [String]()
    private var recentRecords: [String: DevelopmentRecord.Version]
    private var failures = Set<String>()
    private var isSuspended = false
    private var continuations = [CheckedContinuation<Void, Never>]()

    init(recentRecords records: [String: DevelopmentRecord.Version]) {
        self.recentRecords = records
    }

    func setFailure(goalID: String, fails: Bool) {
        if fails {
            failures.insert(goalID)
        } else {
            failures.remove(goalID)
        }
    }

    func suspend() {
        isSuspended = true
    }

    func resume() {
        isSuspended = false
        let continuations = self.continuations
        self.continuations.removeAll()
        for continuation in continuations {
            continuation.resume()
        }
    }

    func execute(goalId: String) async throws -> DevelopmentRecord.Version? {
        goalIDs.append(goalId)
        if isSuspended {
            await withCheckedContinuation { continuations.append($0) }
        }
        if failures.contains(goalId) { throw DevelopmentGoalListTestError.failed }
        return recentRecords[goalId]
    }
}

enum DevelopmentGoalListTestError: Error {
    case failed
}

func makeDevelopmentGoal(
    id: String,
    status: DevelopmentGoal.Status = .inProgress
) throws -> DevelopmentGoal {
    try DevelopmentGoal(
        id: id,
        title: id,
        description: "목표 설명",
        status: status,
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0),
        completedAt: nil
    )
}

func makeDevelopmentRecordVersion(
    recordID id: String
) throws -> DevelopmentRecord.Version {
    try DevelopmentRecord.Version(
        id: "\(id)-v1",
        recordId: id,
        number: 1,
        title: "기록 \(id)",
        markdownContent: "기록 내용",
        kind: .initial,
        sourceVersionId: nil,
        confirmedAt: Date(timeIntervalSince1970: 0)
    )
}
