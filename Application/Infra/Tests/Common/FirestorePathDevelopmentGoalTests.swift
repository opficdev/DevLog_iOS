//
//  FirestorePathDevelopmentGoalTests.swift
//  InfraTests
//
//  Created by opfic on 8/28/26.
//

import Testing
@testable import Infra

struct FirestorePathDevelopmentGoalTests {
    @Test("개발 목표와 기록 경로는 사용자 경로 아래에 중첩한다")
    func 개발_목표와_기록_경로는_사용자_경로_아래에_중첩한다() {
        let goalPath = FirestorePath.developmentGoal("user-1", goalId: "goal-1")
        let recordPath = FirestorePath.developmentRecord(
            "user-1",
            goalId: "goal-1",
            recordId: "record-1"
        )

        #expect(goalPath == "users/user-1/developmentGoals/goal-1")
        #expect(recordPath == "users/user-1/developmentGoals/goal-1/records/record-1")
    }
}
