//
//  TodayWidgetSnapshotFactoryTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/17/26.
//

import Foundation
import Testing
@testable import DevLog

struct TodayWidgetSnapshotFactoryTests {
    @Test("Today 위젯 스냅샷은 화면 규칙과 같은 순서로 섹션과 요약 수치를 만든다")
    func today_위젯_스냅샷은_화면_규칙과_같은_순서로_섹션과_요약_수치를_만든다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 17)))
        let factory = TodayWidgetSnapshotFactory(calendar: calendar)

        let snapshot = factory.makeSnapshot(
            todos: try makeTodayTodos(now: now, calendar: calendar),
            displayOptions: .default,
            now: now
        )

        #expect(snapshot.totalCount == 5)
        #expect(snapshot.focusedCount == 1)
        #expect(snapshot.overdueCount == 1)
        #expect(snapshot.dueSoonCount == 2)
        #expect(snapshot.sections.map(\.category) == ["focused", "overdue", "dueSoon", "later", "unscheduled"])
        #expect(snapshot.sections[0].items.map(\.title) == ["고정된 할 일"])
        #expect(snapshot.sections[1].items.map(\.title) == ["지난 일정"])
        #expect(snapshot.sections[2].items.map(\.title) == ["임박 일정"])
        #expect(snapshot.sections[3].items.map(\.title) == ["나중 일정"])
        #expect(snapshot.sections[4].items.map(\.title) == ["미정 일정"])
    }

    @Test("Today 위젯 스냅샷은 화면과 같은 display option 필터를 적용한다")
    func today_위젯_스냅샷은_화면과_같은_display_option_필터를_적용한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 17)))
        let factory = TodayWidgetSnapshotFactory(calendar: calendar)

        let snapshot = factory.makeSnapshot(
            todos: try makeTodayTodos(now: now, calendar: calendar),
            displayOptions: TodayDisplayOptions(
                dueDateVisibility: .withDueDateOnly,
                focusVisibility: .focusedOnly
            ),
            now: now
        )

        #expect(snapshot.totalCount == 1)
        #expect(snapshot.focusedCount == 1)
        #expect(snapshot.overdueCount == 0)
        #expect(snapshot.dueSoonCount == 1)
        #expect(snapshot.sections.map(\.category) == ["focused"])
        #expect(snapshot.sections[0].items.map(\.title) == ["고정된 할 일"])
    }

    private func makeTodayTodos(
        now: Date,
        calendar: Calendar
    ) throws -> [TodayTodoItem] {
        let overdueDate = try #require(calendar.date(byAdding: .day, value: -1, to: now))
        let dueSoonDate = try #require(calendar.date(byAdding: .day, value: 3, to: now))
        let laterDate = try #require(calendar.date(byAdding: .day, value: 9, to: now))

        return try [
            makeTodayTodoItem(
                id: "todo-1",
                number: 1,
                title: "고정된 할 일",
                isPinned: true,
                dueDate: dueSoonDate
            ),
            makeTodayTodoItem(
                id: "todo-2",
                number: 2,
                title: "지난 일정",
                isPinned: false,
                dueDate: overdueDate
            ),
            makeTodayTodoItem(
                id: "todo-3",
                number: 3,
                title: "임박 일정",
                isPinned: false,
                dueDate: dueSoonDate
            ),
            makeTodayTodoItem(
                id: "todo-4",
                number: 4,
                title: "나중 일정",
                isPinned: false,
                dueDate: laterDate
            ),
            makeTodayTodoItem(
                id: "todo-5",
                number: 5,
                title: "미정 일정",
                isPinned: false,
                dueDate: nil
            )
        ]
    }

    private func makeTodayTodoItem(
        id: String,
        number: Int,
        title: String,
        isPinned: Bool,
        dueDate: Date?
    ) throws -> TodayTodoItem {
        let todo = Todo(
            id: id,
            isPinned: isPinned,
            isCompleted: false,
            isChecked: false,
            number: number,
            title: title,
            content: "",
            createdAt: .now,
            updatedAt: .now,
            completedAt: nil,
            deletedAt: nil,
            dueDate: dueDate,
            tags: [],
            category: .system(.feature)
        )

        return try #require(TodayTodoItem(from: todo))
    }
}
