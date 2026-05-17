//
//  HeatmapWidgetSnapshotFactoryTests.swift
//  DevLogWidgetCoreTests
//
//  Created by opfic on 4/17/26.
//

import Foundation
import Testing
import DevLogCore
import DevLogDomain
@testable import DevLogWidgetCore

struct HeatmapWidgetSnapshotFactoryTests {
    @Test("Heatmap 위젯 스냅샷은 이번 분기 기준 월과 일별 count를 만든다")
    func heatmap_위젯_스냅샷은_이번_분기_기준_월과_일별_count를_만든다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let quarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let mayStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        let juneStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
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
                    createdAt: quarterStart,
                    completedAt: aprilThirdDate
                ),
                makeTodo(
                    id: "todo-completed-may-01",
                    createdAt: quarterStart,
                    completedAt: mayFirstDate
                )
            ],
            deletedTodos: [
                makeTodo(
                    id: "todo-deleted-apr-15",
                    createdAt: quarterStart,
                    deletedAt: aprilFifteenthDate
                )
            ],
            selectedActivityKinds: [.created, .completed],
            quarterStart: quarterStart,
            now: quarterStart
        )

        #expect(snapshot.quarterStart == quarterStart)
        #expect(snapshot.selectedActivityKindRawValues == ["created", "completed"])
        #expect(snapshot.maxCount == 2)
        #expect(snapshot.months.count == 3)
        #expect(snapshot.months.map(\.monthStart) == [
            quarterStart,
            mayStart,
            juneStart
        ])
        #expect(snapshot.months[0].weeks.count == 5)
        #expect(snapshot.months.flatMap(\.weeks).flatMap(\.days).filter(\.isVisible).count == 91)

        let aprilThird = try #require(day(for: DateComponents(year: 2026, month: 4, day: 3), in: snapshot, calendar: calendar))
        #expect(aprilThird.createdCount == 1)
        #expect(aprilThird.completedCount == 1)
        #expect(aprilThird.deletedCount == 0)
        #expect(aprilThird.isVisible)

        let aprilFifteenth = try #require(day(for: DateComponents(year: 2026, month: 4, day: 15), in: snapshot, calendar: calendar))
        #expect(aprilFifteenth.createdCount == 0)
        #expect(aprilFifteenth.completedCount == 0)
        #expect(aprilFifteenth.deletedCount == 1)

        let mayFirst = try #require(day(for: DateComponents(year: 2026, month: 5, day: 1), in: snapshot, calendar: calendar))
        #expect(mayFirst.completedCount == 1)
    }

    @Test("Heatmap 위젯 스냅샷 maxCount는 선택된 activity kind만 기준으로 계산한다")
    func heatmap_위젯_스냅샷_maxCount는_선택된_activity_kind만_기준으로_계산한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let quarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
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
                    createdAt: quarterStart,
                    deletedAt: targetDate
                ),
                makeTodo(
                    id: "deleted-2",
                    createdAt: quarterStart,
                    deletedAt: targetDate
                ),
                makeTodo(
                    id: "deleted-3",
                    createdAt: quarterStart,
                    deletedAt: targetDate
                )
            ],
            selectedActivityKinds: [.deleted],
            quarterStart: quarterStart,
            now: quarterStart
        )

        #expect(snapshot.selectedActivityKindRawValues == ["deleted"])
        #expect(snapshot.maxCount == 3)

        let targetDay = try #require(day(for: DateComponents(year: 2026, month: 4, day: 10), in: snapshot, calendar: calendar))
        #expect(targetDay.createdCount == 2)
        #expect(targetDay.deletedCount == 3)
    }

    @Test("Heatmap 위젯 스냅샷은 분기 시작일은 포함하고 다음 분기 시작일은 제외한다")
    func heatmap_위젯_스냅샷은_분기_시작일은_포함하고_다음_분기_시작일은_제외한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let quarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let nextQuarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)))
        let quarterLastDate = try #require(calendar.date(byAdding: .second, value: -1, to: nextQuarterStart))
        let factory = HeatmapWidgetSnapshotFactory(calendar: calendar)

        let snapshot = factory.makeSnapshot(
            createdTodos: [
                makeTodo(id: "created-quarter-start", createdAt: quarterStart),
                makeTodo(id: "created-next-quarter-start", createdAt: nextQuarterStart)
            ],
            completedTodos: [
                makeTodo(
                    id: "completed-quarter-last-date",
                    createdAt: quarterStart,
                    completedAt: quarterLastDate
                )
            ],
            deletedTodos: [],
            selectedActivityKinds: [.created, .completed],
            quarterStart: quarterStart,
            now: quarterStart
        )

        let aprilFirst = try #require(day(for: DateComponents(year: 2026, month: 4, day: 1), in: snapshot, calendar: calendar))
        let juneThirtieth = try #require(day(for: DateComponents(year: 2026, month: 6, day: 30), in: snapshot, calendar: calendar))

        #expect(aprilFirst.createdCount == 1)
        #expect(juneThirtieth.completedCount == 1)
        #expect(day(for: DateComponents(year: 2026, month: 7, day: 1), in: snapshot, calendar: calendar) == nil)
        #expect(snapshot.maxCount == 1)
    }

    @Test("Heatmap 위젯 스냅샷은 Q4 분기를 다음 해 1월 전까지 만든다")
    func heatmap_위젯_스냅샷은_q4_분기를_다음_해_1월_전까지_만든다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let q4Date = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 10)))
        let octoberStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let novemberStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let decemberStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 1)))
        let decemberLastDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 31)))
        let nextYearStart = try #require(calendar.date(from: DateComponents(year: 2027, month: 1, day: 1)))
        let factory = HeatmapWidgetSnapshotFactory(calendar: calendar)

        let snapshot = factory.makeSnapshot(
            createdTodos: [
                makeTodo(id: "created-december-last-date", createdAt: decemberLastDate),
                makeTodo(id: "created-next-year-start", createdAt: nextYearStart)
            ],
            completedTodos: [],
            deletedTodos: [],
            selectedActivityKinds: [.created],
            quarterStart: q4Date,
            now: q4Date
        )

        let decemberLastDay = try #require(day(for: DateComponents(year: 2026, month: 12, day: 31), in: snapshot, calendar: calendar))

        #expect(snapshot.quarterStart == octoberStart)
        #expect(snapshot.months.map(\.monthStart) == [octoberStart, novemberStart, decemberStart])
        #expect(decemberLastDay.createdCount == 1)
        #expect(day(for: DateComponents(year: 2027, month: 1, day: 1), in: snapshot, calendar: calendar) == nil)
        #expect(snapshot.maxCount == 1)
    }

    private func day(
        for components: DateComponents,
        in snapshot: HeatmapWidgetSnapshot,
        calendar: Calendar
    ) -> WidgetHeatmapDaySnapshot? {
        guard let date = calendar.date(from: components) else { return nil }
        let targetDate = calendar.startOfDay(for: date)

        return snapshot.months
            .flatMap(\.weeks)
            .flatMap(\.days)
            .first { day in
                day.isVisible && calendar.isDate(day.date, inSameDayAs: targetDate)
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
