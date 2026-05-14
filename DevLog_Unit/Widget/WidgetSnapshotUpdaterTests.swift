//
//  WidgetSnapshotUpdaterTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/30/26.
//

import Foundation
import Testing
@testable import DevLog

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
        #expect(snapshot.sections.first?.items.first?.id == todo.id)
    }

    @Test("Heatmap 스냅샷 갱신은 Heatmap 스냅샷을 저장한다")
    func heatmap_스냅샷_갱신은_Heatmap_스냅샷을_저장한다() throws {
        let calendar = Calendar(identifier: .gregorian)
        let quarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 30)))
        let fixture = makeFixture(calendar: calendar)

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
                    completedAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 3)))
                )
            ],
            deletedTodos: [
                makeTodo(
                    id: "deleted",
                    createdAt: quarterStart,
                    deletedAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 4)))
                )
            ],
            selectedActivityKinds: [.created, .completed],
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
            selectedActivityKinds: [.created],
            quarterStart: quarterStart,
            now: now
        )

        fixture.updater.clear()

        #expect(try fixture.snapshotStore.loadTodaySnapshot() == nil)
        #expect(try fixture.snapshotStore.loadHeatmapSnapshot() == nil)
        #expect(fixture.preferenceStore.heatmapActivityTypes().isEmpty)
        #expect(fixture.preferenceStore.todayDisplayOptions() == .default)
    }

    private func makeFixture(
        calendar: Calendar = .current
    ) -> (
        updater: WidgetSnapshotUpdaterImpl,
        snapshotStore: WidgetSnapshotStore,
        preferenceStore: WidgetSnapshotPreferenceStoreImpl
    ) {
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
        return (updater, snapshotStore, preferenceStore)
    }

    private func makeTodo(
        id: String,
        createdAt: Date,
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        dueDate: Date? = nil
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
            dueDate: dueDate,
            tags: [],
            category: .system(.feature)
        )
    }
}
