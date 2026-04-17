//
//  HeatmapWidgetSnapshotFactoryTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/17/26.
//

import Foundation
import Testing
@testable import DevLog

struct HeatmapWidgetSnapshotFactoryTests {
    @Test("Heatmap 위젯 스냅샷은 이번 달 기준 주차와 일별 count를 만든다")
    func heatmap_위젯_스냅샷은_이번_달_기준_주차와_일별_count를_만든다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let monthStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let aprilThirdDate = calendar.date(from: DateComponents(year: 2026, month: 4, day: 3))!
        let mayFirstDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let aprilFifteenthDate = calendar.date(from: DateComponents(year: 2026, month: 4, day: 15))!
        let factory = HeatmapWidgetSnapshotFactory(calendar: calendar)

        let snapshot = factory.makeSnapshot(
            createdTodos: [
                makeTodo(
                    id: "todo-created-apr-03",
                    createdAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 3)))
                ),
                makeTodo(
                    id: "todo-created-mar-31",
                    createdAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 31)))
                )
            ],
            completedTodos: [
                makeTodo(
                    id: "todo-completed-apr-03",
                    createdAt: monthStart,
                    completedAt: aprilThirdDate
                ),
                makeTodo(
                    id: "todo-completed-may-01",
                    createdAt: monthStart,
                    completedAt: mayFirstDate
                )
            ],
            deletedTodos: [
                makeTodo(
                    id: "todo-deleted-apr-15",
                    createdAt: monthStart,
                    deletedAt: aprilFifteenthDate
                )
            ],
            selectedActivityKinds: [.created, .completed],
            monthStart: monthStart,
            now: monthStart
        )

        #expect(snapshot.monthStart == monthStart)
        #expect(snapshot.selectedActivityKindRawValues == ["created", "completed"])
        #expect(snapshot.maxCount == 2)
        #expect(snapshot.weeks.count == 5)
        #expect(snapshot.weeks.flatMap(\.days).filter(\.isVisible).count == 30)

        let aprilThird = try #require(day(for: DateComponents(year: 2026, month: 4, day: 3), in: snapshot, calendar: calendar))
        #expect(aprilThird.createdCount == 1)
        #expect(aprilThird.completedCount == 1)
        #expect(aprilThird.deletedCount == 0)
        #expect(aprilThird.isVisible)

        let aprilFifteenth = try #require(day(for: DateComponents(year: 2026, month: 4, day: 15), in: snapshot, calendar: calendar))
        #expect(aprilFifteenth.createdCount == 0)
        #expect(aprilFifteenth.completedCount == 0)
        #expect(aprilFifteenth.deletedCount == 1)
    }

    @Test("Heatmap 위젯 스냅샷 maxCount는 선택된 activity kind만 기준으로 계산한다")
    func heatmap_위젯_스냅샷_maxCount는_선택된_activity_kind만_기준으로_계산한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let monthStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let targetDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 10)))
        let factory = HeatmapWidgetSnapshotFactory(calendar: calendar)

        let snapshot = factory.makeSnapshot(
            createdTodos: [
                makeTodo(id: "created-1", createdAt: targetDate),
                makeTodo(id: "created-2", createdAt: targetDate)
            ],
            completedTodos: [],
            deletedTodos: [
                makeTodo(
                    id: "deleted-1",
                    createdAt: monthStart,
                    deletedAt: targetDate
                ),
                makeTodo(
                    id: "deleted-2",
                    createdAt: monthStart,
                    deletedAt: targetDate
                ),
                makeTodo(
                    id: "deleted-3",
                    createdAt: monthStart,
                    deletedAt: targetDate
                )
            ],
            selectedActivityKinds: [.deleted],
            monthStart: monthStart,
            now: monthStart
        )

        #expect(snapshot.selectedActivityKindRawValues == ["deleted"])
        #expect(snapshot.maxCount == 3)

        let targetDay = try #require(day(for: DateComponents(year: 2026, month: 4, day: 10), in: snapshot, calendar: calendar))
        #expect(targetDay.createdCount == 2)
        #expect(targetDay.deletedCount == 3)
    }

    private func day(
        for components: DateComponents,
        in snapshot: HeatmapWidgetSnapshot,
        calendar: Calendar
    ) -> WidgetHeatmapDaySnapshot? {
        guard let date = calendar.date(from: components) else { return nil }
        let targetDate = calendar.startOfDay(for: date)

        return snapshot.weeks
            .flatMap(\.days)
            .first { day in
                calendar.isDate(day.date, inSameDayAs: targetDate)
            }
    }

    private func makeTodo(
        id: String,
        createdAt: Date,
        completedAt: Date? = nil,
        deletedAt: Date? = nil
    ) -> Todo {
        Todo(
            id: id,
            isPinned: false,
            isCompleted: completedAt != nil,
            isChecked: false,
            number: 1,
            title: id,
            content: "",
            createdAt: createdAt,
            updatedAt: createdAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: nil,
            tags: [],
            category: .system(.feature)
        )
    }
}
