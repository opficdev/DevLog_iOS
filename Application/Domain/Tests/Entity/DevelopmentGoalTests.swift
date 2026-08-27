//
//  DevelopmentGoalTests.swift
//  DomainTests
//
//  Created by opfic on 8/27/26.
//

import Foundation
import Testing
@testable import Domain

struct DevelopmentGoalTests {
    @Test("공백과 줄바꿈만 있는 목표 제목은 거부한다")
    func 공백과_줄바꿈만_있는_목표_제목은_거부한다() {
        expectDomainError(.invalidDevelopmentGoalTitle) {
            _ = try makeGoal(title: " \n ")
        }
    }

    @Test("진행 중 목표는 완료와 보관으로 전환할 수 있다")
    func 진행_중_목표는_완료와_보관으로_전환할_수_있다() throws {
        let goal = try makeGoal()

        try goal.validateTransition(to: .completed)
        try goal.validateTransition(to: .archived)
    }

    @Test("완료와 보관 목표는 진행 중으로만 전환할 수 있다")
    func 완료와_보관_목표는_진행_중으로만_전환할_수_있다() throws {
        let completedGoal = try makeGoal(status: .completed)
        let archivedGoal = try makeGoal(status: .archived)

        try completedGoal.validateTransition(to: .inProgress)
        try archivedGoal.validateTransition(to: .inProgress)
    }

    @Test("정의하지 않은 목표 상태 전환은 거부한다")
    func 정의하지_않은_목표_상태_전환은_거부한다() throws {
        let completedGoal = try makeGoal(status: .completed)

        expectDomainError(.invalidDevelopmentGoalTransition) {
            try completedGoal.validateTransition(to: .archived)
        }
    }

    @Test("목표 조회 조건은 상태 필터만 보유한다")
    func 목표_조회_조건은_상태_필터만_보유한다() {
        let query = DevelopmentGoal.Query(status: .inProgress)

        #expect(query.status == .inProgress)
    }

    @Test("완료 검증 스냅샷은 목표와 전체 기록을 함께 보유한다")
    func 완료_검증_스냅샷은_목표와_전체_기록을_함께_보유한다() throws {
        let goal = try makeGoal()
        let record = try makeInitialDraftRecord()
        let snapshot = DevelopmentGoal.CompletionSnapshot(goal: goal, records: [record])

        #expect(snapshot.goal == goal)
        #expect(snapshot.records == [record])
    }
}

private func makeGoal(
    title: String = "개발 목표",
    status: DevelopmentGoal.Status = .inProgress
) throws -> DevelopmentGoal {
    try DevelopmentGoal(
        id: "goal-1",
        title: title,
        markdownDescription: "설명",
        status: status,
        createdAt: .distantPast,
        updatedAt: .distantPast,
        completedAt: status == .completed ? .distantFuture : nil
    )
}

private func makeInitialDraftRecord() throws -> DevelopmentRecord {
    let draft = try DevelopmentRecord.Draft(
        title: "초안",
        markdownContent: "본문",
        baseVersionID: nil,
        updatedAt: .distantPast
    )
    return try DevelopmentRecord(
        id: "record-1",
        goalID: "goal-1",
        currentVersion: nil,
        draft: draft,
        createdAt: .distantPast
    )
}

private func expectDomainError(
    _ expected: DomainLayerError,
    operation: () throws -> Void
) {
    do {
        try operation()
        Issue.record("DomainLayerError가 필요")
    } catch let error as DomainLayerError {
        #expect(error == expected)
    } catch {
        Issue.record("예상하지 않은 오류: \(error)")
    }
}
