//
//  WidgetSnapshotUpdaterTests.swift
//  WidgetTests
//
//  Created by opfic on 4/30/26.
//

import Foundation
import Core
import Data
import Testing
@testable import Widget
@testable import WidgetCore

struct WidgetSnapshotUpdaterTests {
    @Test("Today 스냅샷 갱신은 Today 스냅샷을 저장한다")
    func today_스냅샷_갱신은_Today_스냅샷을_저장한다() throws {
        let fixture = makeFixture()
        let now = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 30)))
        let todo = makeTodo(
            id: "today",
            createdAt: now,
            dueDate: now
        )

        fixture.updater.updateTodaySnapshot(
            todos: [todo],
            displayOptions: .default,
            now: now
        )

        let snapshot = try #require(try fixture.snapshotStore.loadTodaySnapshot())
        #expect(snapshot.totalCount == 1)
        #expect(snapshot.items.first?.id == todo.id)
    }

    @Test("Heatmap 스냅샷 갱신은 Heatmap 스냅샷을 저장한다")
    func heatmap_스냅샷_갱신은_Heatmap_스냅샷을_저장한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let quarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 30)))
        let completedAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 3)))
        let deletedAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 4)))
        let fixture = makeFixture(calendar: calendar)
        fixture.preferenceStore.setHeatmapActivityTypes(["created", "completed"])

        fixture.updater.updateHeatmapSnapshot(
            createdTodos: [
                makeTodo(
                    id: "created",
                    createdAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 2)))
                )
            ],
            completedTodos: [
                makeTodo(
                    id: "completed",
                    createdAt: quarterStart,
                    completedAt: completedAt
                )
            ],
            deletedTodos: [
                makeTodo(
                    id: "deleted",
                    createdAt: quarterStart,
                    deletedAt: deletedAt
                )
            ],
            quarterStart: quarterStart,
            now: now
        )

        let snapshot = try #require(try fixture.snapshotStore.loadHeatmapSnapshot())
        #expect(snapshot.quarterStart == quarterStart)
        #expect(snapshot.selectedActivityKindRawValues == ["created", "completed"])
        #expect(snapshot.maxCount == 1)
    }

    @Test("WidgetSnapshotUpdaterImpl는 모든 위젯 스냅샷을 삭제한다")
    func widgetSnapshotUpdater는_모든_위젯_스냅샷을_삭제한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let quarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 30)))
        let fixture = makeFixture(calendar: calendar)
        let todo = makeTodo(
            id: "today",
            createdAt: now,
            dueDate: now
        )
        fixture.preferenceStore.setHeatmapActivityTypes(["created"])
        fixture.preferenceStore.setTodayDisplayOptions(
            TodayDisplayOptions(
                dueDateVisibility: .withDueDateOnly,
                focusVisibility: .focusedOnly
            )
        )

        fixture.updater.updateTodaySnapshot(
            todos: [todo],
            displayOptions: .default,
            now: now
        )
        fixture.updater.updateHeatmapSnapshot(
            createdTodos: [
                makeTodo(
                    id: "created",
                    createdAt: now
                )
            ],
            completedTodos: [],
            deletedTodos: [],
            quarterStart: quarterStart,
            now: now
        )

        fixture.updater.clear()

        #expect(try fixture.snapshotStore.loadTodaySnapshot() == nil)
        #expect(try fixture.snapshotStore.loadHeatmapSnapshot() == nil)
        #expect(fixture.preferenceStore.heatmapActivityTypes().isEmpty)
        #expect(fixture.preferenceStore.todayDisplayOptions() == .default)
    }

    @Test("저장된 원본 재생성은 네트워크 fetch 없이 현재 설정을 반영한다")
    func 저장된_원본_재생성은_네트워크_fetch_없이_현재_설정을_반영한다() throws {
        let now = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 30)))
        let fixture = makeFixture()

        fixture.updater.updateTodaySnapshot(
            todos: [
                makeTodo(
                    id: "focused",
                    createdAt: now,
                    dueDate: now,
                    isPinned: true
                ),
                makeTodo(
                    id: "normal",
                    createdAt: now,
                    dueDate: now
                )
            ],
            now: now
        )
        fixture.preferenceStore.setTodayDisplayOptions(
            TodayDisplayOptions(
                dueDateVisibility: .all,
                focusVisibility: .focusedOnly
            )
        )

        fixture.updater.updateTodaySnapshot(now: now)

        let snapshot = try #require(try fixture.snapshotStore.loadTodaySnapshot())
        #expect(snapshot.totalCount == 1)
        #expect(snapshot.items.map(\.id) == ["focused"])
    }

    @Test("저장된 원본이 없으면 재생성 요청은 기존 스냅샷을 덮지 않는다")
    func 저장된_원본이_없으면_재생성_요청은_기존_스냅샷을_덮지_않는다() throws {
        let now = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 30)))
        let fixture = makeFixture()
        try fixture.snapshotStore.saveTodaySnapshot(
            TodayWidgetSnapshot(
                generatedAt: now,
                totalCount: 1,
                focusedCount: 0,
                overdueCount: 0,
                dueSoonCount: 1,
                items: [
                    WidgetTodayTodoSnapshot(
                        id: "existing",
                        number: 1,
                        title: "existing",
                        isPinned: false,
                        dueDate: now
                    )
                ]
            )
        )

        fixture.updater.updateTodaySnapshot(now: now)

        let snapshot = try #require(try fixture.snapshotStore.loadTodaySnapshot())
        #expect(snapshot.totalCount == 1)
        #expect(snapshot.items.map(\.id) == ["existing"])
    }

    @Test("Todo 삭제 원본 반영은 Today 원본에만 있는 Todo도 Heatmap 삭제 활동으로 갱신한다")
    func todo_삭제_원본_반영은_today_원본에만_있는_todo도_heatmap_삭제_활동으로_갱신한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let quarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let createdAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 2)))
        let deletedAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 3)))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 30)))
        let fixture = makeFixture(calendar: calendar)
        fixture.preferenceStore.setHeatmapActivityTypes(["deleted"])
        let todo = makeTodo(
            id: "todo",
            createdAt: createdAt,
            dueDate: now
        )

        fixture.updater.updateTodaySnapshot(
            todos: [todo],
            now: now
        )
        fixture.updater.updateHeatmapSnapshot(
            createdTodos: [],
            completedTodos: [],
            deletedTodos: [],
            quarterStart: quarterStart,
            now: now
        )

        fixture.updater.deleteTodoSnapshot(todoId: todo.id, deletedAt: deletedAt, now: now)

        let todaySnapshot = try #require(try fixture.snapshotStore.loadTodaySnapshot())
        let heatmapSnapshot = try #require(try fixture.snapshotStore.loadHeatmapSnapshot())
        #expect(todaySnapshot.totalCount == 0)
        #expect(heatmapSnapshot.maxCount == 1)
    }

    private func makeFixture(
        calendar: Calendar = .current
    ) -> Fixture {
        let suiteName = "WidgetSnapshotUpdaterTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        let snapshotStore = WidgetSnapshotStore(
            store: WidgetSharedDefaultsStore(userDefaults: userDefaults)
        )
        let preferenceStore = WidgetSnapshotPreferenceStoreImpl(
            userDefaults: userDefaults
        )
        let updater = WidgetSnapshotUpdaterImpl(
            snapshotStore: snapshotStore,
            preferenceStore: preferenceStore,
            heatmapFactory: HeatmapWidgetSnapshotFactory(calendar: calendar)
        )
        return Fixture(
            updater: updater,
            snapshotStore: snapshotStore,
            preferenceStore: preferenceStore
        )
    }

    private func makeTodo(
        id: String,
        createdAt: Date,
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        dueDate: Date? = nil,
        isPinned: Bool = false
    ) -> WidgetTodoSnapshot {
        WidgetTodoSnapshot(
            id: id,
            number: 1,
            title: id,
            isPinned: isPinned,
            createdAt: createdAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: dueDate
        )
    }
}

private struct Fixture {
    let updater: WidgetSnapshotUpdaterImpl
    let snapshotStore: WidgetSnapshotStore
    let preferenceStore: WidgetSnapshotPreferenceStoreImpl
}
