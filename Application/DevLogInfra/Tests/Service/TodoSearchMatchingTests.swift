//
//  TodoSearchMatchingTests.swift
//  DevLogInfraTests
//
//  Created by opfic on 6/26/26.
//

import Foundation
import Testing
import DevLogData
@testable import DevLogInfra

struct TodoSearchMatchingTests {
    @Test("#숫자 검색어는 Todo 번호를 문자열 기반으로 부분 검색한다")
    func 해시_숫자_검색어는_Todo_번호를_문자열_기반으로_부분_검색한다() {
        let todo = makeTodo(number: 123)

        #expect(todo.matchesSearchKeyword("#1"))
        #expect(todo.matchesSearchKeyword("#12"))
    }

    @Test("# 단독 검색어는 Todo 번호로 매칭하지 않는다")
    func 해시_단독_검색어는_Todo_번호로_매칭하지_않는다() {
        let todo = makeTodo(number: 123)

        #expect(!todo.matchesSearchKeyword("#"))
    }

    private func makeTodo(number: Int) -> TodoResponse {
        TodoResponse(
            id: "todo-id",
            isPinned: false,
            isCompleted: false,
            isChecked: false,
            number: number,
            title: "title",
            content: "content",
            createdAt: .now,
            updatedAt: .now,
            completedAt: nil,
            deletedAt: nil,
            dueDate: nil,
            tags: [],
            category: .raw("feature")
        )
    }
}
