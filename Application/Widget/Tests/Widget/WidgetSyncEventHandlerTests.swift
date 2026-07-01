//
//  WidgetSyncEventHandlerTests.swift
//  WidgetTests
//
//  Created by opfic on 4/30/26.
//

import Foundation
import Testing
import Core
import Data
import WidgetCore
@testable import Widget

struct WidgetSyncEventHandlerTests {
    @Test("위젯 동기화 요청 이벤트는 Today와 Heatmap 스냅샷을 갱신한다")
    func 위젯_동기화_요청_이벤트는_today와_heatmap_스냅샷을_갱신한다() async throws {
        let calendar = Calendar.current
        let now = Date()
        let quarterStart = calendar.startOfQuarter(for: now)
        let fixture = makeFixture()

        await fixture.repository.setTodos(
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

        try await waitUntil {
            fixture.snapshotUpdater.hasTodayUpdate && fixture.snapshotUpdater.hasHeatmapUpdate
        }

        let todayUpdates = fixture.snapshotUpdater.todayUpdates
        let heatmapUpdates = fixture.snapshotUpdater.heatmapUpdates
        let calls = await fixture.repository.calledCalls()

        #expect(todayUpdates.first?.todos.map(\.id) == ["today"])
        #expect(heatmapUpdates.first?.createdTodos.map(\.id) == ["created"])
        #expect(heatmapUpdates.first?.completedTodos.map(\.id) == ["completed"])
        #expect(heatmapUpdates.first?.deletedTodos.map(\.id) == ["deleted"])
        #expect(todayUpdates.first?.now == heatmapUpdates.first?.now)
        #expect(calls.count == 5)
        #expect(Set(calls.map(\.sortTarget)) == Set([
            .dueDate,
            .updatedAt,
            .createdAt,
            .completedAt,
            .deletedAt
        ]))
    }

    @Test("Today 스냅샷 조회 실패는 Heatmap 스냅샷 갱신을 막지 않는다")
    func today_스냅샷_조회_실패는_heatmap_스냅샷_갱신을_막지_않는다() async throws {
        let calendar = Calendar.current
        let now = Date()
        let quarterStart = calendar.startOfQuarter(for: now)
        let fixture = makeFixture()

        await fixture.repository.setTodos(
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
        await fixture.repository.setFailingSortTargets([.dueDate])

        fixture.bus.publish(.syncRequested)

        try await waitUntil {
            fixture.snapshotUpdater.hasHeatmapUpdate
        }

        #expect(fixture.snapshotUpdater.todayUpdates.isEmpty)
        #expect(fixture.snapshotUpdater.heatmapUpdates.first?.createdTodos.map(\.id) == ["created"])
        #expect(fixture.snapshotUpdater.heatmapUpdates.first?.completedTodos.map(\.id) == ["completed"])
        #expect(fixture.snapshotUpdater.heatmapUpdates.first?.deletedTodos.map(\.id) == ["deleted"])
    }

    @Test("Heatmap 스냅샷 조회 실패는 Today 스냅샷 갱신을 막지 않는다")
    func heatmap_스냅샷_조회_실패는_today_스냅샷_갱신을_막지_않는다() async throws {
        let now = Date()
        let fixture = makeFixture()

        await fixture.repository.setTodos(
            todayTodosWithDueDate: [
                makeTodo(id: "today", createdAt: now, dueDate: now)
            ]
        )
        await fixture.repository.setFailingSortTargets([.createdAt])

        fixture.bus.publish(.syncRequested)

        try await waitUntil {
            fixture.snapshotUpdater.hasTodayUpdate
        }

        #expect(fixture.snapshotUpdater.todayUpdates.first?.todos.map(\.id) == ["today"])
        #expect(fixture.snapshotUpdater.heatmapUpdates.isEmpty)
    }

    @Test("스냅샷 재생성 요청 이벤트는 저장된 원본을 재사용한다")
    func 스냅샷_재생성_요청_이벤트는_저장된_원본을_재사용한다() async throws {
        let fixture = makeFixture()

        fixture.bus.publish(.refreshRequested)

        try await waitUntil {
            fixture.snapshotUpdater.refreshCallCount == 2
        }

        #expect(await fixture.repository.calledCalls().isEmpty)
    }

    private func makeFixture() -> Fixture {
        let bus = WidgetSyncEventBusImpl()
        let repository = WidgetTodoSnapshotRepositorySpy()
        let snapshotUpdater = WidgetSnapshotUpdaterSpy()
        let handler = WidgetSyncEventHandler(
            eventBus: bus,
            repository: repository,
            snapshotUpdater: snapshotUpdater
        )

        return Fixture(
            bus: bus,
            repository: repository,
            snapshotUpdater: snapshotUpdater,
            handler: handler
        )
    }

    private func makeTodo(
        id: String,
        createdAt: Date,
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        dueDate: Date? = nil
    ) -> WidgetTodoSnapshot {
        WidgetTodoSnapshot(
            id: id,
            number: 1,
            title: id,
            isPinned: false,
            createdAt: createdAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: dueDate
        )
    }
}

private struct Fixture {
    let bus: WidgetSyncEventBusImpl
    let repository: WidgetTodoSnapshotRepositorySpy
    let snapshotUpdater: WidgetSnapshotUpdaterSpy
    let handler: WidgetSyncEventHandler
}

private actor WidgetTodoSnapshotRepositorySpy: WidgetTodoSnapshotRepository {
    struct Call {
        let sortTarget: TodoQuery.SortTarget
    }

    private var calls = [Call]()
    private var failingSortTargets = Set<TodoQuery.SortTarget>()
    private var todayTodosWithDueDate = [WidgetTodoSnapshot]()
    private var todayTodosWithoutDueDate = [WidgetTodoSnapshot]()
    private var createdTodos = [WidgetTodoSnapshot]()
    private var completedTodos = [WidgetTodoSnapshot]()
    private var deletedTodos = [WidgetTodoSnapshot]()

    func setTodos(
        todayTodosWithDueDate: [WidgetTodoSnapshot] = [],
        todayTodosWithoutDueDate: [WidgetTodoSnapshot] = [],
        createdTodos: [WidgetTodoSnapshot] = [],
        completedTodos: [WidgetTodoSnapshot] = [],
        deletedTodos: [WidgetTodoSnapshot] = []
    ) {
        self.todayTodosWithDueDate = todayTodosWithDueDate
        self.todayTodosWithoutDueDate = todayTodosWithoutDueDate
        self.createdTodos = createdTodos
        self.completedTodos = completedTodos
        self.deletedTodos = deletedTodos
    }

    func setFailingSortTargets(_ failingSortTargets: Set<TodoQuery.SortTarget>) {
        self.failingSortTargets = failingSortTargets
    }
    func fetchTodayTodos(
        dueDateFilter: TodoQuery.DueDateFilter,
        sortTarget: TodoQuery.SortTarget,
        sortOrder: TodoQuery.SortOrder,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot] {
        calls.append(Call(sortTarget: sortTarget))

        if failingSortTargets.contains(sortTarget) {
            throw WidgetTodoSnapshotRepositorySpyError.fetchTodosFailed
        }

        switch sortTarget {
        case .dueDate:
            return todayTodosWithDueDate
        case .updatedAt:
            return todayTodosWithoutDueDate
        case .createdAt, .completedAt, .deletedAt:
            throw WidgetTodoSnapshotRepositorySpyError.unexpectedCall
        }
    }

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot] {
        calls.append(Call(sortTarget: sortTarget))

        if failingSortTargets.contains(sortTarget) {
            throw WidgetTodoSnapshotRepositorySpyError.fetchTodosFailed
        }

        switch sortTarget {
        case .createdAt:
            return createdTodos
        case .completedAt:
            return completedTodos
        case .deletedAt:
            return deletedTodos
        case .dueDate, .updatedAt:
            throw WidgetTodoSnapshotRepositorySpyError.unexpectedCall
        }
    }

    func calledCalls() -> [Call] {
        calls
    }
}

private final class WidgetSnapshotUpdaterSpy: WidgetSnapshotUpdater {
    struct TodayUpdate {
        let todos: [WidgetTodoSnapshot]
        let now: Date
    }

    struct HeatmapUpdate {
        let createdTodos: [WidgetTodoSnapshot]
        let completedTodos: [WidgetTodoSnapshot]
        let deletedTodos: [WidgetTodoSnapshot]
        let quarterStart: Date
        let now: Date
    }

    private let lock = NSRecursiveLock()
    private var storedTodayUpdates = [TodayUpdate]()
    private var storedHeatmapUpdates = [HeatmapUpdate]()
    private(set) var clearCallCount = 0

    var todayUpdates: [TodayUpdate] {
        lock.lock()
        defer { lock.unlock() }
        return storedTodayUpdates
    }

    var heatmapUpdates: [HeatmapUpdate] {
        lock.lock()
        defer { lock.unlock() }
        return storedHeatmapUpdates
    }

    var hasTodayUpdate: Bool { !todayUpdates.isEmpty }
    var hasHeatmapUpdate: Bool { !heatmapUpdates.isEmpty }

    var refreshCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedRefreshCallCount
    }

    private var storedRefreshCallCount = 0

    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot]?,
        displayOptions: TodayDisplayOptions?,
        now: Date
    ) {
        if let todos {
            appendTodayUpdate(TodayUpdate(todos: todos, now: now))
        } else {
            incrementRefreshCallCount()
        }
    }

    func updateHeatmapSnapshot(
        createdTodos: [WidgetTodoSnapshot]?,
        completedTodos: [WidgetTodoSnapshot]?,
        deletedTodos: [WidgetTodoSnapshot]?,
        quarterStart: Date?,
        now: Date
    ) {
        if let createdTodos,
           let completedTodos,
           let deletedTodos,
           let quarterStart {
            appendHeatmapUpdate(HeatmapUpdate(
                createdTodos: createdTodos,
                completedTodos: completedTodos,
                deletedTodos: deletedTodos,
                quarterStart: quarterStart,
                now: now
            ))
        } else {
            incrementRefreshCallCount()
        }
    }

    func upsertTodoSnapshot(
        _ todo: WidgetTodoSnapshot,
        now: Date
    ) { }

    func deleteTodoSnapshot(
        todoId: String,
        deletedAt: Date,
        now: Date
    ) { }

    func restoreTodoSnapshot(
        todoId: String,
        now: Date
    ) { }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        clearCallCount += 1
    }

    private func appendTodayUpdate(_ update: TodayUpdate) {
        lock.lock()
        defer { lock.unlock() }
        storedTodayUpdates.append(update)
    }

    private func appendHeatmapUpdate(_ update: HeatmapUpdate) {
        lock.lock()
        defer { lock.unlock() }
        storedHeatmapUpdates.append(update)
    }

    private func incrementRefreshCallCount() {
        lock.lock()
        defer { lock.unlock() }
        storedRefreshCallCount += 1
    }
}

private enum WidgetTodoSnapshotRepositorySpyError: Error {
    case fetchTodosFailed
    case unexpectedCall
}

private func waitUntil(
    timeout: Duration = .seconds(1), pollInterval: Duration = .milliseconds(20), _ condition: @escaping () -> Bool
) async throws {
    let continuousClock = ContinuousClock()
    let deadline = continuousClock.now + timeout

    while !condition() && continuousClock.now < deadline {
        try await Task.sleep(for: pollInterval)
    }
}
