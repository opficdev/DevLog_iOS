//
//  WidgetSyncEventTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/29/26.
//

import Foundation
import Testing
@testable import DevLog

struct WidgetSyncEventTests {
    @Test("Today 스냅샷 변경 이벤트는 Todo 목록과 표시 옵션을 담는다")
    func today_스냅샷_변경_이벤트는_Todo_목록과_표시_옵션을_담는다() throws {
        let todo = try makeTodayTodoItem()
        let displayOptions = TodayDisplayOptions(
            dueDateVisibility: .withDueDateOnly,
            focusVisibility: .focusedOnly
        )
        let event = WidgetSyncEvent.todaySnapshotChanged(
            todos: [todo],
            displayOptions: displayOptions
        )

        guard case .todaySnapshotChanged(let todos, let options) = event else {
            Issue.record("Today snapshot event expected")
            return
        }
        #expect(todos == [todo])
        #expect(options == displayOptions)
    }

    @Test("Heatmap 스냅샷 변경 이벤트는 선택된 활동 종류를 담는다")
    func heatmap_스냅샷_변경_이벤트는_선택된_활동_종류를_담는다() {
        let activityKinds: Set<ActivityKind> = [.created, .completed]
        let event = WidgetSyncEvent.heatmapSnapshotChanged(
            selectedActivityKinds: activityKinds
        )

        guard case .heatmapSnapshotChanged(let selectedActivityKinds) = event else {
            Issue.record("Heatmap snapshot event expected")
            return
        }
        #expect(selectedActivityKinds == activityKinds)
    }

    private func makeTodayTodoItem() throws -> TodayTodoItem {
        let todo = Todo(
            id: "todo-1",
            isPinned: true,
            isCompleted: false,
            isChecked: false,
            number: 1,
            title: "위젯 동기화",
            content: "",
            createdAt: .now,
            updatedAt: .now,
            completedAt: nil,
            deletedAt: nil,
            dueDate: .now,
            tags: [],
            category: .system(.feature)
        )

        return try #require(TodayTodoItem(from: todo))
    }
}
