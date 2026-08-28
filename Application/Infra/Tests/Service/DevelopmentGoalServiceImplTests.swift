//
//  DevelopmentGoalServiceImplTests.swift
//  InfraTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import FirebaseFirestore
@testable import Infra

struct DevelopmentGoalServiceImplTests {
    @Test("개발 목표 문서는 Data 응답으로 변환한다")
    func 개발_목표_문서는_Data_응답으로_변환한다() throws {
        let response = try #require(
            DevelopmentGoalServiceImpl.makeResponse(documentId: "goal-1", data: makeData())
        )

        #expect(response.id == "goal-1")
        #expect(response.markdownDescription == "설명")
        #expect(response.status == "inProgress")
    }

    @Test("목표 상태 전환은 진행 중과 보관 사이에서만 저장 데이터를 만든다")
    func 목표_상태_전환은_진행_중과_보관_사이에서만_저장_데이터를_만든다() {
        let data = DevelopmentGoalServiceImpl.makeTransitionData(
            recordData: makeData(),
            request: .init(status: "archived")
        )

        #expect(data?["status"] as? String == "archived")
        #expect(data?["completedAt"] == nil)
    }

    @Test("완료 상태를 포함한 목표 상태 전환은 저장 데이터를 만들지 않는다")
    func 완료_상태를_포함한_목표_상태_전환은_저장_데이터를_만들지_않는다() {
        let requestedCompletion = DevelopmentGoalServiceImpl.makeTransitionData(
            recordData: makeData(),
            request: .init(status: "completed")
        )
        let existingCompletion = DevelopmentGoalServiceImpl.makeTransitionData(
            recordData: makeData(status: "completed"),
            request: .init(status: "archived")
        )

        #expect(requestedCompletion == nil)
        #expect(existingCompletion == nil)
    }

    @Test("개발 기록 문서는 경로 식별값을 응답에 복원한다")
    func 개발_기록_문서는_경로_식별값을_응답에_복원한다() throws {
        let response = try #require(
            DevelopmentRecordDocumentMapper().map(
                goalId: "goal-1",
                documentId: "record-1",
                data: [
                    DevelopmentRecordFieldKey.createdAt.rawValue: Timestamp(date: Date(timeIntervalSince1970: 0)),
                    DevelopmentRecordFieldKey.draft.rawValue: [
                        DevelopmentRecordDraftFieldKey.title.rawValue: "기록",
                        DevelopmentRecordDraftFieldKey.markdownContent.rawValue: "본문",
                        DevelopmentRecordDraftFieldKey.updatedAt.rawValue:
                            Timestamp(date: Date(timeIntervalSince1970: 0))
                    ]
                ]
            )
        )

        #expect(response.goalId == "goal-1")
        #expect(response.id == "record-1")
        #expect(response.draft?.baseVersionId == nil)
    }

    private func makeData(status: String = "inProgress") -> [String: Any] {
        [
            "title": "목표",
            "markdownDescription": "설명",
            "status": status,
            "createdAt": Timestamp(date: Date(timeIntervalSince1970: 0)),
            "updatedAt": Timestamp(date: Date(timeIntervalSince1970: 0))
        ]
    }
}
