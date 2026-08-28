//
//  DevelopmentGoalMappingTests.swift
//  DataTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import Domain
@testable import Data

struct DevelopmentGoalMappingTests {
    @Test("저장 목표 응답은 markdownDescription을 Domain 설명으로 변환한다")
    func 저장_목표_응답은_markdownDescription을_Domain_설명으로_변환한다() throws {
        let response = makeGoalResponse()

        let goal = try response.toDomain()

        #expect(goal.description == "설명")
        #expect(goal.status == .inProgress)
    }

    @Test("상태 조건은 Data 상태 값으로 변환한다")
    func 상태_조건은_Data_상태_값으로_변환한다() {
        let query = DevelopmentGoalQuery.fromDomain(.init(status: .completed))

        #expect(query.status == .completed)
    }

    @Test("Data 상태는 Domain 상태로 변환한다")
    func Data_상태는_Domain_상태로_변환한다() {
        #expect(DevelopmentGoalStatus.archived.toDomain() == .archived)
    }
}

private func makeGoalResponse() -> DevelopmentGoalResponse {
    DevelopmentGoalResponse(
        id: "goal-1",
        title: "목표",
        markdownDescription: "설명",
        status: .inProgress,
        createdAt: .distantPast,
        updatedAt: .distantPast,
        completedAt: nil
    )
}
