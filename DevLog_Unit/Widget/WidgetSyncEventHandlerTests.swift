//
//  WidgetSyncEventHandlerTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/30/26.
//

import Foundation
import Testing
@testable import DevLog

struct WidgetSyncEventHandlerTests {
    @Test("위젯 동기화 요청 이벤트는 Today와 Heatmap 스냅샷을 갱신한다")
    func 위젯_동기화_요청_이벤트는_today와_heatmap_스냅샷을_갱신한다() async throws {
        let calendar = Calendar.current
        let now = Date()
        let quarterStart = calendar.startOfQuarter(for: now)
        let fixture = makeFixture(calendar: calendar)

        await fixture.todoRepository.setTodos(
            todayTodosWithDueDate: [
                makeTodo(id: "today", createdAt: now, dueDate: now)
            ],
            createdTodos: [
                makeTodo(id: "created", createdAt: now)
            ],
            completedTodos: [
                makeTodo(id: "completed", createdAt: quarterStart, completedAt: now)
            ],
            deletedTodos: [
                makeTodo(id: "deleted", createdAt: quarterStart, deletedAt: now)
            ]
        )

        fixture.bus.publish(.syncRequested)

        let todaySnapshot = try await loadTodaySnapshot(from: fixture.snapshotStore)
        let heatmapSnapshot = try await loadHeatmapSnapshot(from: fixture.snapshotStore)
        let queries = await fixture.todoRepository.calledQueries()

        #expect(todaySnapshot.totalCount == 1)
        #expect(heatmapSnapshot.maxCount == 3)
        #expect(queries.count == 5)
        #expect(Set(queries.map(\.sortTarget)) == Set([
            .dueDate,
            .updatedAt,
            .createdAt,
            .completedAt,
            .deletedAt
        ]))
        _ = fixture.handler
    }

    private func makeFixture(
        calendar: Calendar
    ) -> (
        bus: WidgetSyncEventBusImpl,
        todoRepository: WidgetSyncTodoRepositorySpy,
        snapshotStore: WidgetSnapshotStore,
        handler: WidgetSyncEventHandler
    ) {
        let suiteName = "WidgetSyncEventHandlerTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        let bus = WidgetSyncEventBusImpl()
        let todoRepository = WidgetSyncTodoRepositorySpy()
        let snapshotStore = WidgetSnapshotStore(
            store: WidgetSharedDefaultsStore(userDefaults: userDefaults)
        )
        let preferenceStore = WidgetSnapshotPreferenceStore(
            userDefaults: userDefaults
        )
        let updater = WidgetSnapshotUpdater(
            snapshotStore: snapshotStore,
            preferenceStore: preferenceStore,
            heatmapFactory: HeatmapWidgetSnapshotFactory(calendar: calendar)
        )
        let handler = WidgetSyncEventHandler(
            eventBus: bus,
            repository: todoRepository,
            snapshotUpdater: updater
        )

        return (bus, todoRepository, snapshotStore, handler)
    }

    private func loadTodaySnapshot(
        from snapshotStore: WidgetSnapshotStore
    ) async throws -> TodayWidgetSnapshot {
        for _ in 0..<20 {
            if let snapshot = try snapshotStore.loadTodaySnapshot() {
                return snapshot
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        return try #require(try snapshotStore.loadTodaySnapshot())
    }

    private func loadHeatmapSnapshot(
        from snapshotStore: WidgetSnapshotStore
    ) async throws -> HeatmapWidgetSnapshot {
        for _ in 0..<20 {
            if let snapshot = try snapshotStore.loadHeatmapSnapshot() {
                return snapshot
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        return try #require(try snapshotStore.loadHeatmapSnapshot())
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

private actor WidgetSyncTodoRepositorySpy: TodoRepository {
    private var queries = [TodoQuery]()
    private var todayTodosWithDueDate = [Todo]()
    private var todayTodosWithoutDueDate = [Todo]()
    private var createdTodos = [Todo]()
    private var completedTodos = [Todo]()
    private var deletedTodos = [Todo]()

    func setTodos(
        todayTodosWithDueDate: [Todo] = [],
        todayTodosWithoutDueDate: [Todo] = [],
        createdTodos: [Todo] = [],
        completedTodos: [Todo] = [],
        deletedTodos: [Todo] = []
    ) {
        self.todayTodosWithDueDate = todayTodosWithDueDate
        self.todayTodosWithoutDueDate = todayTodosWithoutDueDate
        self.createdTodos = createdTodos
        self.completedTodos = completedTodos
        self.deletedTodos = deletedTodos
    }

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)

        let items: [Todo]
        switch query.sortTarget {
        case .dueDate:
            items = todayTodosWithDueDate
        case .updatedAt:
            items = todayTodosWithoutDueDate
        case .createdAt:
            items = createdTodos
        case .completedAt:
            items = completedTodos
        case .deletedAt:
            items = deletedTodos
        }

        return TodoPage(items: items, nextCursor: nil)
    }

    func fetchTodo(_ todoId: String) async throws -> Todo {
        throw DataError.invalidData("WidgetSyncTodoRepositorySpy.fetchTodo should not be called")
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReference] {
        throw DataError.invalidData("WidgetSyncTodoRepositorySpy.fetchReferences should not be called")
    }

    func upsertTodo(_ todo: Todo) async throws {
        throw DataError.invalidData("WidgetSyncTodoRepositorySpy.upsertTodo should not be called")
    }

    func deleteTodo(_ todoId: String) async throws {
        throw DataError.invalidData("WidgetSyncTodoRepositorySpy.deleteTodo should not be called")
    }

    func undoDeleteTodo(_ todoId: String) async throws {
        throw DataError.invalidData("WidgetSyncTodoRepositorySpy.undoDeleteTodo should not be called")
    }

    func calledQueries() -> [TodoQuery] {
        queries
    }
}
