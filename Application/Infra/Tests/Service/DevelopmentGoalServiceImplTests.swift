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

    @Test("개발 기록 문서는 경로 식별값을 응답에 복원한다")
    func 개발_기록_문서는_경로_식별값을_응답에_복원한다() throws {
        let response = try #require(
            DevelopmentRecordDocumentMapper().map(
                goalId: "goal-1",
                documentId: "record-1",
                data: [
                    DevelopmentRecordFieldKey.createdAt.rawValue: Timestamp(date: .distantPast),
                    DevelopmentRecordFieldKey.draft.rawValue: [
                        DevelopmentRecordDraftFieldKey.title.rawValue: "기록",
                        DevelopmentRecordDraftFieldKey.markdownContent.rawValue: "본문",
                        DevelopmentRecordDraftFieldKey.updatedAt.rawValue: Timestamp(date: .distantPast)
                    ]
                ]
            )
        )

        #expect(response.goalId == "goal-1")
        #expect(response.id == "record-1")
        #expect(response.draft?.baseVersionId == nil)
    }

    private func makeData() -> [String: Any] {
        [
            "title": "목표",
            "markdownDescription": "설명",
            "status": "inProgress",
            "createdAt": Timestamp(date: .distantPast),
            "updatedAt": Timestamp(date: .distantPast)
        ]
    }
}
