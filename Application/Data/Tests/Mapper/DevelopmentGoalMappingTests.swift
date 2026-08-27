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

    @Test("상태 조건은 저장 문자열로 변환한다")
    func 상태_조건은_저장_문자열로_변환한다() {
        let query = DevelopmentGoalQuery.fromDomain(.init(status: .completed))

        #expect(query.status == "completed")
    }

    @Test("알 수 없는 저장 상태는 유효하지 않은 데이터 오류를 만든다")
    func 알_수_없는_저장_상태는_유효하지_않은_데이터_오류를_만든다() {
        #expect(throws: DataLayerError.self) {
            _ = try DevelopmentGoal.Status.fromStorageValue("unknown")
        }
    }
}

private func makeGoalResponse() -> DevelopmentGoalResponse {
    DevelopmentGoalResponse(
        id: "goal-1",
        title: "목표",
        markdownDescription: "설명",
        status: "inProgress",
        createdAt: .distantPast,
        updatedAt: .distantPast,
        completedAt: nil
    )
}
