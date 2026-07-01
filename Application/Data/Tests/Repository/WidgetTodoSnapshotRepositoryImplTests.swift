//
//  WidgetTodoSnapshotRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 6/8/26.
//

import Foundation
import Testing
import Core
import Domain
@testable import Data

struct WidgetTodoSnapshotRepositoryImplTests {
    @Test("Today 위젯 Todo 조회는 TodoService query와 snapshot 매핑을 사용한다")
    func today_위젯_todo_조회는_todoservice_query와_snapshot_매핑을_사용한다() async throws {
        let todoServiceSpy = WidgetTodoSnapshotTodoServiceSpy()
        let repository = WidgetTodoSnapshotRepositoryImpl(todoService: todoServiceSpy)
        let now = Date(timeIntervalSince1970: 100)
        let todo = makeTodoResponse(id: "today", createdAt: now, dueDate: now)

        await todoServiceSpy.setTodos([todo], for: .dueDate)

        let snapshots = try await repository.fetchTodayTodos(
            dueDateFilter: .withDueDate,
            sortTarget: .dueDate,
            sortOrder: .oldest,
            pageSize: 100
        )
        let queries = await todoServiceSpy.calledQueries()

        #expect(snapshots == [makeSnapshot(id: "today", createdAt: now, dueDate: now)])
        #expect(queries == [
            TodoQuery(
                completionFilter: .incomplete,
                dueDateFilter: .withDueDate,
                sortTarget: .dueDate,
                sortOrder: .oldest,
                pageSize: 100,
                fetchAllPages: true
            )
        ])
    }

    @Test("Heatmap 위젯 Todo 조회는 TodoService query와 snapshot 매핑을 사용한다")
    func heatmap_위젯_todo_조회는_todoservice_query와_snapshot_매핑을_사용한다() async throws {
        let todoServiceSpy = WidgetTodoSnapshotTodoServiceSpy()
        let repository = WidgetTodoSnapshotRepositoryImpl(todoService: todoServiceSpy)
        let quarterStart = Date(timeIntervalSince1970: 100)
        let nextQuarterStart = Date(timeIntervalSince1970: 200)
        let todo = makeTodoResponse(id: "created", createdAt: quarterStart)

        await todoServiceSpy.setTodos([todo], for: .createdAt)

        let snapshots = try await repository.fetchHeatmapTodos(
            sortTarget: .createdAt,
            quarterStart: quarterStart,
            nextQuarterStart: nextQuarterStart,
            pageSize: 100
        )
        let queries = await todoServiceSpy.calledQueries()

        #expect(snapshots == [makeSnapshot(id: "created", createdAt: quarterStart)])
        #expect(queries == [
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: .createdAt,
                pageSize: 100,
                fetchAllPages: true
            )
        ])
    }

    private func makeSnapshot(
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

    private func makeTodoResponse(
        id: String,
        createdAt: Date,
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        dueDate: Date? = nil
    ) -> TodoResponse {
        TodoResponse(
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
            category: .raw(SystemTodoCategory.feature.rawValue)
        )
    }
}

private actor WidgetTodoSnapshotTodoServiceSpy: TodoService {
    private var queries = [TodoQuery]()
    private var todosBySortTarget = [TodoQuery.SortTarget: [TodoResponse]]()

    func setTodos(_ todos: [TodoResponse], for sortTarget: TodoQuery.SortTarget) {
        todosBySortTarget[sortTarget] = todos
    }

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursorDTO?) async throws -> TodoPageResponse {
        queries.append(query)

        return TodoPageResponse(
            items: todosBySortTarget[query.sortTarget] ?? [],
            nextCursor: nil
        )
    }

    func upsertTodo(request: TodoRequest) async throws {
        throw WidgetTodoSnapshotTodoServiceSpyError.unexpectedCall
    }

    func deleteTodo(todoId: String) async throws {
        throw WidgetTodoSnapshotTodoServiceSpyError.unexpectedCall
    }

    func undoDeleteTodo(todoId: String) async throws {
        throw WidgetTodoSnapshotTodoServiceSpyError.unexpectedCall
    }

    func fetchTodo(todoId: String) async throws -> TodoResponse {
        throw WidgetTodoSnapshotTodoServiceSpyError.unexpectedCall
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReferenceResponse] {
        throw WidgetTodoSnapshotTodoServiceSpyError.unexpectedCall
    }

    func calledQueries() -> [TodoQuery] {
        queries
    }
}

private enum WidgetTodoSnapshotTodoServiceSpyError: Error {
    case unexpectedCall
}
