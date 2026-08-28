//
//  DevelopmentGoalServiceImplTests.swift
//  InfraTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import FirebaseFirestore
import Data
@testable import Infra

struct DevelopmentGoalServiceImplTests {
    @Test("공백뿐인 목표 제목은 저장 전에 거부한다")
    func 공백뿐인_목표_제목은_저장_전에_거부한다() {
        do {
            try DevelopmentGoalServiceImpl.validateTitle(" \n ")
            Issue.record("DataLayerError.invalidDevelopmentGoalTitle이 필요")
        } catch DataLayerError.invalidDevelopmentGoalTitle {
        } catch {
            Issue.record("예상하지 않은 오류: \(error)")
        }
    }

    @Test("의미 있는 목표 제목은 저장 전에 허용한다")
    func 의미_있는_목표_제목은_저장_전에_허용한다() throws {
        try DevelopmentGoalServiceImpl.validateTitle(" 목표 ")
    }

    @Test("개발 목표 문서는 Data 응답으로 변환한다")
    func 개발_목표_문서는_Data_응답으로_변환한다() throws {
        let response = try #require(
            try DevelopmentGoalServiceImpl.makeResponse(documentId: "goal-1", data: makeData())
        )

        #expect(response.id == "goal-1")
        #expect(response.markdownDescription == "설명")
        #expect(response.status == .inProgress)
    }

    @Test("목표 상태 전환은 진행 중과 보관 사이에서만 저장 데이터를 만든다")
    func 목표_상태_전환은_진행_중과_보관_사이에서만_저장_데이터를_만든다() throws {
        let data = try DevelopmentGoalServiceImpl.makeTransitionData(
            recordData: makeData(),
            request: .init(status: .archived)
        )

        #expect(data?["status"] as? String == "archived")
        #expect(data?["completedAt"] == nil)
    }

    @Test("완료 요청과 완료 목표의 보관 전환은 저장 데이터를 만들지 않는다")
    func 완료_요청과_완료_목표의_보관_전환은_저장_데이터를_만들지_않는다() throws {
        let requestedCompletion = try DevelopmentGoalServiceImpl.makeTransitionData(
            recordData: makeData(),
            request: .init(status: .completed)
        )
        let archivedCompletion = try DevelopmentGoalServiceImpl.makeTransitionData(
            recordData: makeData(status: "completed"),
            request: .init(status: .archived)
        )

        #expect(requestedCompletion == nil)
        #expect(archivedCompletion == nil)
    }

    @Test("완료 목표는 진행 중으로 되돌리고 완료 시각을 삭제한다")
    func 완료_목표는_진행_중으로_되돌리고_완료_시각을_삭제한다() throws {
        let data = try DevelopmentGoalServiceImpl.makeTransitionData(
            recordData: makeData(status: "completed"),
            request: .init(status: .inProgress)
        )

        #expect(data?["status"] as? String == "inProgress")
        #expect(data?["completedAt"] is FieldValue)
    }

    @Test("유효하지 않은 저장 상태는 전환 데이터를 만들지 않고 오류를 던진다")
    func 유효하지_않은_저장_상태는_전환_데이터를_만들지_않고_오류를_던진다() {
        #expect(throws: DataLayerError.self) {
            _ = try DevelopmentGoalServiceImpl.makeTransitionData(
                recordData: makeData(status: "inProgres"),
                request: .init(status: .archived)
            )
        }
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
