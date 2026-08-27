//
//  TodoGoalMappingTests.swift
//  DataTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import Domain
@testable import Data

struct TodoGoalMappingTests {
    @Test("Todo 목표 연결은 저장 요청에 보존한다")
    func Todo_목표_연결은_저장_요청에_보존한다() {
        let todo = makeTodo(goalId: "goal-1")

        let request = TodoRequest.fromDomain(todo)

        #expect(request.goalId == "goal-1")
    }

    @Test("Todo 초안 목표 연결은 저장 요청에 보존한다")
    func Todo_초안_목표_연결은_저장_요청에_보존한다() {
        let draft = TodoDraft(todo: makeTodo(goalId: "goal-1"))

        let request = TodoRequest.fromDomain(draft)

        #expect(request.goalId == "goal-1")
    }

    @Test("목표 연결이 없는 Todo 응답은 nil로 변환한다")
    func 목표_연결이_없는_Todo_응답은_nil로_변환한다() throws {
        let response = makeResponse(goalId: nil)

        let todo = try response.toDomain()

        #expect(todo.goalId == nil)
    }

    private func makeTodo(goalId: String?) -> Todo {
        Todo(
            id: "todo-1",
            isPinned: false,
            isCompleted: false,
            isChecked: false,
            number: 1,
            title: "Todo",
            content: "내용",
            createdAt: .distantPast,
            updatedAt: .distantPast,
            completedAt: nil,
            deletedAt: nil,
            dueDate: nil,
            tags: [],
            category: .system(.feature),
            goalId: goalId
        )
    }

    private func makeResponse(goalId: String?) -> TodoResponse {
        TodoResponse(
            id: "todo-1",
            isPinned: false,
            isCompleted: false,
            isChecked: false,
            number: 1,
            title: "Todo",
            content: "내용",
            createdAt: .distantPast,
            updatedAt: .distantPast,
            completedAt: nil,
            deletedAt: nil,
            dueDate: nil,
            tags: [],
            category: .decoded(.system(.feature)),
            goalId: goalId
        )
    }
}
