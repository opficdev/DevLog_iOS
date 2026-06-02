//
//  WidgetSyncEventHandlerTests.swift
//  DevLogDataTests
//
//  Created by opfic on 4/30/26.
//

import Foundation
import Testing
import DevLogCore
import DevLogDomain
@testable import DevLogData

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

        try await waitUntil {
            fixture.snapshotUpdater.hasTodayUpdate && fixture.snapshotUpdater.hasHeatmapUpdate
        }

        let todayUpdates = fixture.snapshotUpdater.todayUpdates
        let heatmapUpdates = fixture.snapshotUpdater.heatmapUpdates
        let queries = await fixture.todoRepository.calledQueries()

        #expect(todayUpdates.first?.todos.map(\.id) == ["today"])
        #expect(heatmapUpdates.first?.createdTodos.map(\.id) == ["created"])
        #expect(heatmapUpdates.first?.completedTodos.map(\.id) == ["completed"])
        #expect(heatmapUpdates.first?.deletedTodos.map(\.id) == ["deleted"])
        #expect(todayUpdates.first?.now == heatmapUpdates.first?.now)
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

    @Test("Today 스냅샷 조회 실패는 Heatmap 스냅샷 갱신을 막지 않는다")
    func today_스냅샷_조회_실패는_heatmap_스냅샷_갱신을_막지_않는다() async throws {
        let calendar = Calendar.current
        let now = Date()
        let quarterStart = calendar.startOfQuarter(for: now)
        let fixture = makeFixture(calendar: calendar)

        await fixture.todoRepository.setTodos(
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
        await fixture.todoRepository.setFailingSortTargets([.dueDate])

        fixture.bus.publish(.syncRequested)

        try await waitUntil {
            fixture.snapshotUpdater.hasHeatmapUpdate
        }

        #expect(fixture.snapshotUpdater.todayUpdates.isEmpty)
        #expect(fixture.snapshotUpdater.heatmapUpdates.first?.createdTodos.map(\.id) == ["created"])
        #expect(fixture.snapshotUpdater.heatmapUpdates.first?.completedTodos.map(\.id) == ["completed"])
        #expect(fixture.snapshotUpdater.heatmapUpdates.first?.deletedTodos.map(\.id) == ["deleted"])
        _ = fixture.handler
    }

    @Test("Heatmap 스냅샷 조회 실패는 Today 스냅샷 갱신을 막지 않는다")
    func heatmap_스냅샷_조회_실패는_today_스냅샷_갱신을_막지_않는다() async throws {
        let calendar = Calendar.current
        let now = Date()
        let fixture = makeFixture(calendar: calendar)

        await fixture.todoRepository.setTodos(
            todayTodosWithDueDate: [
                makeTodo(id: "today", createdAt: now, dueDate: now)
            ]
        )
        await fixture.todoRepository.setFailingSortTargets([.createdAt])

        fixture.bus.publish(.syncRequested)

        try await waitUntil {
            fixture.snapshotUpdater.hasTodayUpdate
        }

        #expect(fixture.snapshotUpdater.todayUpdates.first?.todos.map(\.id) == ["today"])
        #expect(fixture.snapshotUpdater.heatmapUpdates.isEmpty)
        _ = fixture.handler
    }

    private func makeFixture(calendar: Calendar) -> Fixture {
        let bus = WidgetSyncEventBusImpl()
        let todoRepository = WidgetSyncTodoRepositorySpy()
        let snapshotUpdater = WidgetSnapshotUpdaterSpy()
        let handler = WidgetSyncEventHandler(
            eventBus: bus,
            repository: todoRepository,
            snapshotUpdater: snapshotUpdater
        )

        return Fixture(
            bus: bus,
            todoRepository: todoRepository,
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

private struct Fixture {
    let bus: WidgetSyncEventBusImpl
    let todoRepository: WidgetSyncTodoRepositorySpy
    let snapshotUpdater: WidgetSnapshotUpdaterSpy
    let handler: WidgetSyncEventHandler
}

private actor WidgetSyncTodoRepositorySpy: TodoRepository {
    private var queries = [TodoQuery]()
    private var failingSortTargets = Set<TodoQuery.SortTarget>()
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

    func setFailingSortTargets(_ failingSortTargets: Set<TodoQuery.SortTarget>) {
        self.failingSortTargets = failingSortTargets
    }

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)

        if failingSortTargets.contains(query.sortTarget) {
            throw WidgetSyncTodoRepositorySpyError.fetchTodosFailed
        }

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
        throw WidgetSyncTodoRepositorySpyError.unexpectedCall
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReference] {
        throw WidgetSyncTodoRepositorySpyError.unexpectedCall
    }

    func upsertTodo(_ todo: Todo) async throws {
        throw WidgetSyncTodoRepositorySpyError.unexpectedCall
    }

    func upsertTodo(_ todoDraft: TodoDraft) async throws {
        throw WidgetSyncTodoRepositorySpyError.unexpectedCall
    }

    func deleteTodo(_ todoId: String) async throws {
        throw WidgetSyncTodoRepositorySpyError.unexpectedCall
    }

    func undoDeleteTodo(_ todoId: String) async throws {
        throw WidgetSyncTodoRepositorySpyError.unexpectedCall
    }

    func calledQueries() -> [TodoQuery] {
        queries
    }
}

private final class WidgetSnapshotUpdaterSpy: WidgetSnapshotUpdater {
    struct TodayUpdate {
        let todos: [WidgetTodoSnapshot]
        let displayOptions: TodayDisplayOptions?
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

    var hasTodayUpdate: Bool {
        !todayUpdates.isEmpty
    }

    var hasHeatmapUpdate: Bool {
        !heatmapUpdates.isEmpty
    }

    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot],
        now: Date
    ) {
        appendTodayUpdate(
            TodayUpdate(
                todos: todos,
                displayOptions: nil,
                now: now
            )
        )
    }

    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot],
        displayOptions: TodayDisplayOptions,
        now: Date
    ) {
        appendTodayUpdate(
            TodayUpdate(
                todos: todos,
                displayOptions: displayOptions,
                now: now
            )
        )
    }

    func updateHeatmapSnapshot(
        createdTodos: [WidgetTodoSnapshot],
        completedTodos: [WidgetTodoSnapshot],
        deletedTodos: [WidgetTodoSnapshot],
        quarterStart: Date,
        now: Date
    ) {
        appendHeatmapUpdate(
            HeatmapUpdate(
                createdTodos: createdTodos,
                completedTodos: completedTodos,
                deletedTodos: deletedTodos,
                quarterStart: quarterStart,
                now: now
            )
        )
    }

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
}

private enum WidgetSyncTodoRepositorySpyError: Error {
    case fetchTodosFailed
    case unexpectedCall
}

private func waitUntil(
    timeout: Duration = .seconds(1),
    pollInterval: Duration = .milliseconds(20),
    _ condition: @escaping () -> Bool
) async throws {
    let continuousClock = ContinuousClock()
    let deadline = continuousClock.now + timeout

    while !condition() && continuousClock.now < deadline {
        try await Task.sleep(for: pollInterval)
    }
}
