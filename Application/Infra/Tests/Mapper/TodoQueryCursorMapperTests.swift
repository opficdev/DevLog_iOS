//
//  TodoQueryCursorMapperTests.swift
//  InfraTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import FirebaseFirestore
import Core
import Data
@testable import Infra

struct TodoQueryCursorMapperTests {
    @Test("마감일 cursor는 주 정렬 값과 수정일, 문서 ID를 순서대로 만든다")
    func 마감일_cursor는_주_정렬_값과_수정일_문서_ID를_순서대로_만든다() throws {
        let primaryDate = Date(timeIntervalSince1970: 10)
        let secondaryDate = Date(timeIntervalSince1970: 20)
        let query = TodoQuery(sortTarget: .dueDate)
        let cursor = TodoCursorDTO(
            primarySortDate: primaryDate,
            secondarySortDate: secondaryDate,
            documentID: "todo-1"
        )

        let values = try #require(TodoQueryCursorMapper.makeValues(query: query, cursor: cursor))

        #expect(values.count == 3)
        #expect((values[0] as? Timestamp)?.dateValue() == primaryDate)
        #expect((values[1] as? Timestamp)?.dateValue() == secondaryDate)
        #expect(values[2] as? String == "todo-1")
    }

    @Test("정렬과 완료 필터는 기존 Firestore 필드 규칙으로 변환한다")
    func 정렬과_완료_필터는_기존_Firestore_필드_규칙으로_변환한다() {
        #expect(TodoQueryCursorMapper.fieldName(for: .updatedAt) == "updatedAt")
        #expect(TodoQueryCursorMapper.isDescending(.latest))
        #expect(!TodoQueryCursorMapper.isDescending(.oldest))
        #expect(TodoQueryCursorMapper.isCompletedValue(for: .all) == nil)
        #expect(TodoQueryCursorMapper.isCompletedValue(for: .incomplete) == false)
        #expect(TodoQueryCursorMapper.isCompletedValue(for: .completed) == true)
    }
}
