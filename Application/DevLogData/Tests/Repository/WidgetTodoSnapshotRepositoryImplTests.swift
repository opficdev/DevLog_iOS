//
//  WidgetTodoSnapshotRepositoryImplTests.swift
//  DevLogDataTests
//
//  Created by opfic on 6/8/26.
//

import Foundation
import Testing
import DevLogCore
import DevLogDomain
@testable import DevLogData

struct WidgetTodoSnapshotRepositoryImplTests {
    @Test("Today 위젯 Todo 조회는 기존 TodoRepository query와 snapshot 매핑을 사용한다")
    func today_위젯_todo_조회는_기존_todorepository_query와_snapshot_매핑을_사용한다() async throws {
        let repositorySpy = TodoRepositorySpy()
        let repository = WidgetTodoSnapshotRepositoryImpl(repository: repositorySpy)
        let now = Date(timeIntervalSince1970: 100)
        let todo = makeTodo(id: "today", createdAt: now, dueDate: now)

        await repositorySpy.setTodos([todo], for: .dueDate)

        let snapshots = try await repository.fetchTodayTodos(
            dueDateFilter: .withDueDate,
            sortTarget: .dueDate,
            sortOrder: .oldest,
            pageSize: 100
        )
        let queries = await repositorySpy.calledQueries()

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

    @Test("Heatmap 위젯 Todo 조회는 기존 TodoRepository query와 snapshot 매핑을 사용한다")
    func heatmap_위젯_todo_조회는_기존_todorepository_query와_snapshot_매핑을_사용한다() async throws {
        let repositorySpy = TodoRepositorySpy()
        let repository = WidgetTodoSnapshotRepositoryImpl(repository: repositorySpy)
        let quarterStart = Date(timeIntervalSince1970: 100)
        let nextQuarterStart = Date(timeIntervalSince1970: 200)
        let todo = makeTodo(id: "created", createdAt: quarterStart)

        await repositorySpy.setTodos([todo], for: .createdAt)

        let snapshots = try await repository.fetchHeatmapTodos(
            sortTarget: .createdAt,
            quarterStart: quarterStart,
            nextQuarterStart: nextQuarterStart,
            pageSize: 100
        )
        let queries = await repositorySpy.calledQueries()

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
}

private actor TodoRepositorySpy: TodoRepository {
    private var queries = [TodoQuery]()
    private var todosBySortTarget = [TodoQuery.SortTarget: [Todo]]()

    func setTodos(_ todos: [Todo], for sortTarget: TodoQuery.SortTarget) {
        todosBySortTarget[sortTarget] = todos
    }

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)

        return TodoPage(
            items: todosBySortTarget[query.sortTarget] ?? [],
            nextCursor: nil
        )
    }

    func fetchTodo(_ todoId: String) async throws -> Todo {
        throw TodoRepositorySpyError.unexpectedCall
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReference] {
        throw TodoRepositorySpyError.unexpectedCall
    }

    func upsertTodo(_ todo: Todo) async throws {
        throw TodoRepositorySpyError.unexpectedCall
    }

    func upsertTodo(_ todoDraft: TodoDraft) async throws {
        throw TodoRepositorySpyError.unexpectedCall
    }

    func deleteTodo(_ todoId: String) async throws {
        throw TodoRepositorySpyError.unexpectedCall
    }

    func undoDeleteTodo(_ todoId: String) async throws {
        throw TodoRepositorySpyError.unexpectedCall
    }

    func calledQueries() -> [TodoQuery] {
        queries
    }
}

private enum TodoRepositorySpyError: Error {
    case unexpectedCall
}
