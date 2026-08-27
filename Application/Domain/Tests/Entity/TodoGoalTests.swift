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
    @Test("Todo 생성자의 goalId 기본값은 nil이다")
    func Todo_생성자의_goalId_기본값은_nil이다() {
        let todo = Todo(
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
            category: .system(.feature)
        )

        #expect(todo.goalId == nil)
    }

    @Test("TodoDraft 생성자의 goalId 기본값은 nil이다")
    func TodoDraft_생성자의_goalId_기본값은_nil이다() {
        let draft = TodoDraft(
            id: "todo-1",
            isPinned: false,
            isCompleted: false,
            isChecked: false,
            title: "할 일",
            content: "내용",
            createdAt: .distantPast,
            updatedAt: .distantPast,
            completedAt: nil,
            dueDate: nil,
            tags: [],
            category: .system(.feature)
        )

        #expect(draft.goalId == nil)
    }

    @Test("goalId 인자와 TodoDraft 복사는 연결 대상을 보존한다")
    func goalId_인자와_TodoDraft_복사는_연결_대상을_보존한다() {
        let todo = makeTodo(goalId: "goal-1")
        let draft = TodoDraft(todo: todo)

        #expect(todo.goalId == "goal-1")
        #expect(draft.goalId == "goal-1")
    }

    @Test("TodoDraft 동등성 비교는 goalId 변경을 감지한다")
    func TodoDraft_동등성_비교는_goalId_변경을_감지한다() {
        let todo = makeTodo(goalId: "goal-1")
        let linkedDraft = TodoDraft(todo: todo)
        var unlinkedDraft = linkedDraft
        unlinkedDraft.goalId = nil

        #expect(linkedDraft != unlinkedDraft)
    }
}

private func makeTodo(goalId: String? = nil) -> Todo {
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
        goalId: goalId
    )
}
