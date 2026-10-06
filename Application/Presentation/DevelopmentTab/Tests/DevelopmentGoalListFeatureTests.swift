//
//  DevelopmentGoalListFeatureTests.swift
//  DevelopmentTabTests
//
//  Created by opfic on 10/5/26.
//

import Testing
@testable import DevelopmentTab

@MainActor
struct DevelopmentGoalListFeatureTests {
    @Test("최근 기록은 카드가 나타날 때 조회하고 조회 중이거나 캐시가 있으면 중복 조회하지 않는다")
    func lazyRecentRecordAndCache() async throws {
        let goal = try makeDevelopmentGoal(id: "goal")
        let version = try makeDevelopmentRecordVersion(recordID: "record")
        let adapter = StoreTestAdapter(
            goals: [goal],
            recentRecords: ["goal": version]
        )
        await adapter.load(.selected)
        #expect(await adapter.recentRecordSpy.goalIDs.isEmpty)

        await adapter.recentRecordSpy.suspend()
        await adapter.send(.cardAppeared("goal"))
        #expect(adapter.state.recentRecords["goal"] == .loading)
        await adapter.send(.cardAppeared("goal"))
        #expect(adapter.state.recentRecords["goal"] == .loading)
        await adapter.recentRecordSpy.resume()
        await adapter.settle()
        await adapter.send(.cardDisappeared("goal"))
        await adapter.load(.cardAppeared("goal"))
        #expect(adapter.state.recentRecords["goal"] == .loaded(version))
        #expect(await adapter.recentRecordSpy.goalIDs == ["goal"])
    }

    @Test("최근 기록 조회 실패는 해당 카드에만 반영하며 갱신하면 다시 조회한다")
    func recordFailurePreservesList() async throws {
        let goals = try [makeDevelopmentGoal(id: "a"), makeDevelopmentGoal(id: "b")]
        let adapter = StoreTestAdapter(goals: goals)
        await adapter.recentRecordSpy.setFailure(goalID: "a", fails: true)
        await adapter.load(.selected)
        await adapter.load(.cardAppeared("a"))
        await adapter.load(.cardAppeared("b"))
        #expect(adapter.state.goals == goals)
        #expect(!adapter.state.hasLoadFailure)
        #expect(adapter.state.recentRecords["a"] == .failed)
        #expect(adapter.state.recentRecords["b"] == .loaded(nil))
        await adapter.load(.cardAppeared("a"))
        #expect(await adapter.recentRecordSpy.goalIDs == ["a", "b"])

        await adapter.recentRecordSpy.setFailure(goalID: "a", fails: false)
        await adapter.load(.refresh)
        #expect(adapter.state.recentRecords["a"] == .loaded(nil))
        #expect(await adapter.recentRecordSpy.goalIDs.count == 4)
    }

    @Test("목표 상태 변경 후 목록과 개수를 갱신하고 이전 기록 응답은 무시한다")
    func refreshUpdatesStatusAndRejectsStaleRecords() async throws {
        let adapter = try StoreTestAdapter(
            goals: [makeDevelopmentGoal(id: "goal")]
        )
        await adapter.load(.selected)
        await adapter.load(.cardAppeared("goal"))
        let recordRevision = adapter.state.recordRevision
        let goal = try makeDevelopmentGoal(id: "goal", status: .completed)
        await adapter.goalsSpy.setResult(.success([goal]))
        await adapter.send(.showDetail("goal"))
        await adapter.load(.sheet(.dismiss))
        #expect(adapter.state.filteredGoals.isEmpty)
        #expect(adapter.state.count(for: .completed) == 1)
        await adapter.send(.recentRecordLoaded("goal", .failed, revision: recordRevision))
        #expect(adapter.state.recentRecords["goal"] == nil)
        await adapter.send(.selectStatus(.completed))
        await adapter.load(.cardAppeared("goal"))
        #expect(adapter.state.recentRecords["goal"] == .loaded(nil))
    }

    @Test("이전 목록 요청의 성공과 실패 응답은 최신 목록을 덮어쓰지 않는다")
    func staleGoalResponses() async throws {
        let adapter = try StoreTestAdapter(
            goals: [makeDevelopmentGoal(id: "goal")]
        )
        await adapter.load(.selected)
        let requestID = adapter.state.requestID
        await adapter.load(.refresh)
        let state = adapter.state
        await adapter.send(.goalsLoaded([], requestID: requestID))
        await adapter.send(.goalsFailed(requestID: requestID))
        #expect(adapter.state == state)
    }
}
