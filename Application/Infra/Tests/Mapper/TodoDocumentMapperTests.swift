//
//  TodoDocumentMapperTests.swift
//  InfraTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import FirebaseFirestore
import Data
@testable import Infra

struct TodoDocumentMapperTests {
    @Test("목표 연결 해제 요청은 goalId 삭제 값을 만든다")
    func 목표_연결_해제_요청은_goalId_삭제_값을_만든다() throws {
        let data = try TodoDocumentMapper.makeDocumentData(from: makeRequest(goalId: nil))

        #expect(data["goalId"] is FieldValue)
    }

    @Test("목표 연결 요청은 goalId 값을 저장한다")
    func 목표_연결_요청은_goalId_값을_저장한다() throws {
        let data = try TodoDocumentMapper.makeDocumentData(from: makeRequest(goalId: "goal-1"))

        #expect(data["goalId"] as? String == "goal-1")
    }

    @Test("goalId 누락과 null은 연결되지 않은 Todo로 읽는다")
    func goalId_누락과_null은_연결되지_않은_Todo로_읽는다() throws {
        let missing = try #require(
            TodoDocumentMapper.makeResponse(documentID: "todo-1", data: makeDocumentData(goalId: nil))
        )
        let null = try #require(
            TodoDocumentMapper.makeResponse(documentID: "todo-2", data: makeDocumentData(goalId: NSNull()))
        )

        #expect(missing.goalId == nil)
        #expect(null.goalId == nil)
    }

    private func makeRequest(goalId: String?) -> TodoRequest {
        TodoRequest(
            id: "todo-1",
            isPinned: false,
            isCompleted: false,
            isChecked: false,
            title: "Todo",
            content: "내용",
            createdAt: .distantPast,
            updatedAt: .distantPast,
            completedAt: nil,
            deletedAt: nil,
            dueDate: nil,
            tags: [],
            category: "feature",
            goalId: goalId
        )
    }

    private func makeDocumentData(goalId: Any?) -> [String: Any] {
        var data: [String: Any] = [
            "number": 1,
            "title": "Todo",
            "createdAt": Timestamp(date: .distantPast),
            "updatedAt": Timestamp(date: .distantPast),
            "category": "feature"
        ]
        if let goalId {
            data["goalId"] = goalId
        }
        return data
    }
}
