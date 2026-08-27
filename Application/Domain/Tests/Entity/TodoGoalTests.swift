//
//  TodoGoalTests.swift
//  DomainTests
//
//  Created by opfic on 8/27/26.
//

import Foundation
import Testing
@testable import Domain

struct TodoGoalTests {
    @Test("기존 Todo initializer 함수 값은 goalID 없이 Todo를 생성한다")
    func 기존_Todo_initializer_함수_값은_goalID_없이_Todo를_생성한다() {
        let initializer = Todo.init(
            id:isPinned:isCompleted:isChecked:number:title:content:createdAt:updatedAt:completedAt:
            deletedAt:dueDate:tags:category:
        )

        let todo = initializer(
            "todo-1",
            false,
            false,
            false,
            1,
            "할 일",
            "내용",
            .distantPast,
            .distantPast,
            nil,
            nil,
            nil,
            [],
            .system(.feature)
        )

        #expect(todo.goalID == nil)
    }

    @Test("기존 TodoDraft initializer 함수 값은 goalID 없이 Draft를 생성한다")
    func 기존_TodoDraft_initializer_함수_값은_goalID_없이_Draft를_생성한다() {
        let initializer = TodoDraft.init(
            id:isPinned:isCompleted:isChecked:title:content:createdAt:updatedAt:completedAt:dueDate:
            tags:category:
        )

        let draft = initializer(
            "todo-1",
            false,
            false,
            false,
            "할 일",
            "내용",
            .distantPast,
            .distantPast,
            nil,
            nil,
            [],
            .system(.feature)
        )

        #expect(draft.goalID == nil)
    }

    @Test("goalID overload와 TodoDraft 복사는 연결 대상을 보존한다")
    func goalID_overload와_TodoDraft_복사는_연결_대상을_보존한다() {
        let todo = makeTodo(goalID: "goal-1")
        let draft = TodoDraft(todo: todo)

        #expect(todo.goalID == "goal-1")
        #expect(draft.goalID == "goal-1")
    }

    @Test("TodoDraft 동등성 비교는 goalID 변경을 감지한다")
    func TodoDraft_동등성_비교는_goalID_변경을_감지한다() {
        let todo = makeTodo(goalID: "goal-1")
        let linkedDraft = TodoDraft(todo: todo)
        var unlinkedDraft = linkedDraft
        unlinkedDraft.goalID = nil

        #expect(linkedDraft != unlinkedDraft)
    }
}

private func makeTodo(goalID: String? = nil) -> Todo {
    Todo(
        id: "todo-1",
        isPinned: false,
        isCompleted: false,
        isChecked: false,
        number: 1,
        title: "할 일",
        content: "내용",
        createdAt: .distantPast,
        updatedAt: .distantPast,
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: .system(.feature),
        goalID: goalID
    )
}
