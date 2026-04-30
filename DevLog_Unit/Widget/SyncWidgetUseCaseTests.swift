//
//  SyncWidgetUseCaseTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/29/26.
//

import Foundation
import Testing
@testable import DevLog

struct SyncWidgetUseCaseTests {
    @Test("Today 이벤트는 Today 스냅샷을 저장하고 Today 위젯을 갱신한다")
    func today_이벤트는_Today_스냅샷을_저장하고_Today_위젯을_갱신한다() async throws {
        let fixture = makeFixture()
        let now = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 29)))
        let todayTodoItem = try makeTodayTodoItem(now: now)
        let useCase = SyncWidgetUseCase(
            todoRepository: StubTodoRepository(),
            widgetRepository: fixture.widgetRepository,
            calendar: Calendar.current
        )

        await useCase.execute(
            .todaySnapshotChanged(
                todos: [todayTodoItem],
                displayOptions: .default
            ),
            now: now
        )

        let snapshot = try #require(fixture.widgetRepository.todaySnapshot)
        #expect(snapshot.totalCount == 1)
        #expect(snapshot.sections.first?.items.first?.id == todayTodoItem.id)
        #expect(fixture.widgetRepository.didReloadTodayWidget)
    }

    @Test("Heatmap 이벤트는 분기 Todo를 조회해 Heatmap 스냅샷을 저장하고 Heatmap 위젯을 갱신한다")
    func heatmap_이벤트는_분기_Todo를_조회해_Heatmap_스냅샷을_저장하고_Heatmap_위젯을_갱신한다() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let quarterStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 29)))
        let todoRepository = StubTodoRepository(
            todosBySortTarget: [
                .createdAt: [
                    makeTodo(
                        id: "created",
                        createdAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 2)))
                    )
                ],
                .completedAt: [
                    makeTodo(
                        id: "completed",
                        createdAt: quarterStart,
                        completedAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 3)))
                    )
                ],
                .deletedAt: [
                    makeTodo(
                        id: "deleted",
                        createdAt: quarterStart,
                        deletedAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 4)))
                    )
                ]
            ]
        )
        let fixture = makeFixture()
        let useCase = SyncWidgetUseCase(
            todoRepository: todoRepository,
            widgetRepository: fixture.widgetRepository,
            heatmapFactory: HeatmapWidgetSnapshotFactory(calendar: calendar),
            calendar: calendar
        )

        await useCase.execute(
            .heatmapSnapshotChanged(selectedActivityKinds: [.created, .completed]),
            now: now
        )

        let snapshot = try #require(fixture.widgetRepository.heatmapSnapshot)
        #expect(snapshot.quarterStart == quarterStart)
        #expect(snapshot.selectedActivityKindRawValues == ["created", "completed"])
        #expect(snapshot.maxCount == 1)
        let queries = await todoRepository.queries
        let sortTargets = Set(queries.map(\.sortTarget))
        #expect(sortTargets == [.createdAt, .completedAt, .deletedAt])
        #expect(queries.count == 3)
        #expect(fixture.widgetRepository.didReloadHeatmapWidget)
    }

    private func makeFixture() -> (widgetRepository: SpyWidgetRepository) {
        (SpyWidgetRepository())
    }

    private func makeTodayTodoItem(now: Date) throws -> TodayTodoItem {
        let todo = makeTodo(
            id: "today",
            createdAt: now,
            dueDate: now
        )

        return try #require(TodayTodoItem(from: todo))
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

private actor StubTodoRepository: TodoRepository {
    private let todosBySortTarget: [TodoQuery.SortTarget: [Todo]]
    private(set) var queries = [TodoQuery]()

    init(todosBySortTarget: [TodoQuery.SortTarget: [Todo]] = [:]) {
        self.todosBySortTarget = todosBySortTarget
    }

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)
        return TodoPage(
            items: todosBySortTarget[query.sortTarget] ?? [],
            nextCursor: nil
        )
    }

    func fetchTodo(_ todoId: String) async throws -> Todo {
        throw TestError.unimplemented
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReference] {
        throw TestError.unimplemented
    }

    func upsertTodo(_ todo: Todo) async throws {
        throw TestError.unimplemented
    }

    func deleteTodo(_ todoId: String) async throws {
        throw TestError.unimplemented
    }

    func undoDeleteTodo(_ todoId: String) async throws {
        throw TestError.unimplemented
    }
}

private final class SpyWidgetRepository: WidgetRepository {
    private(set) var todaySnapshot: TodayWidgetSnapshot?
    private(set) var heatmapSnapshot: HeatmapWidgetSnapshot?
    private(set) var didReloadTodayWidget = false
    private(set) var didReloadHeatmapWidget = false

    func saveTodaySnapshot(_ snapshot: TodayWidgetSnapshot) throws {
        todaySnapshot = snapshot
    }

    func saveHeatmapSnapshot(_ snapshot: HeatmapWidgetSnapshot) throws {
        heatmapSnapshot = snapshot
    }

    func reloadTodayWidget() {
        didReloadTodayWidget = true
    }

    func reloadHeatmapWidget() {
        didReloadHeatmapWidget = true
    }
}

private enum TestError: Error {
    case unimplemented
}
