//
//  TodoRepositoryImplTests.swift
//  DevLogDataTests
//
//  Created by opfic on 6/1/26.
//

import Combine
import Foundation
import Testing
import DevLogCore
import DevLogDomain
@testable import DevLogData

struct TodoRepositoryImplTests {
    @Test("Todo 변경 성공 시 위젯 동기화 이벤트를 발행한다")
    func todo_변경_성공_시_위젯_동기화_이벤트를_발행한다() async throws {
        let fixture = makeFixture()
        let todo = makeTodo()

        try await fixture.repository.upsertTodo(todo)
        try await fixture.repository.deleteTodo(todo.id)
        try await fixture.repository.undoDeleteTodo(todo.id)

        let events = fixture.widgetSyncEventBus.events
        #expect(events == [.syncRequested, .syncRequested, .syncRequested])
    }

    @Test("Todo 변경 실패 시 위젯 동기화 이벤트를 발행하지 않는다")
    func todo_변경_실패_시_위젯_동기화_이벤트를_발행하지_않는다() async throws {
        let fixture = makeFixture()
        let todo = makeTodo()

        await fixture.todoService.setShouldFail(true)

        do {
            try await fixture.repository.upsertTodo(todo)
            Issue.record("upsertTodo should fail")
        } catch {
            #expect(error as? TodoRepositoryImplTestsError == .serviceFailed)
        }
        do {
            try await fixture.repository.deleteTodo(todo.id)
            Issue.record("deleteTodo should fail")
        } catch {
            #expect(error as? TodoRepositoryImplTestsError == .serviceFailed)
        }
        do {
            try await fixture.repository.undoDeleteTodo(todo.id)
            Issue.record("undoDeleteTodo should fail")
        } catch {
            #expect(error as? TodoRepositoryImplTestsError == .serviceFailed)
        }

        let events = fixture.widgetSyncEventBus.events
        #expect(events.isEmpty)
    }

    private func makeFixture() -> Fixture {
        let todoService = TodoServiceSpy()
        let todoCategoryService = TodoCategoryServiceSpy()
        let widgetSyncEventBus = WidgetSyncEventBusSpy()
        let repository = TodoRepositoryImpl(
            todoService: todoService,
            todoCategoryService: todoCategoryService,
            widgetSyncEventBus: widgetSyncEventBus
        )

        return Fixture(
            repository: repository,
            todoService: todoService,
            widgetSyncEventBus: widgetSyncEventBus
        )
    }

    private func makeTodo() -> Todo {
        Todo(
            id: "todo-id",
            isPinned: false,
            isCompleted: false,
            isChecked: false,
            number: 1,
            title: "title",
            content: "content",
            createdAt: .now,
            updatedAt: .now,
            completedAt: nil,
            deletedAt: nil,
            dueDate: nil,
            tags: [],
            category: .system(.feature)
        )
    }
}

private struct Fixture {
    let repository: TodoRepositoryImpl
    let todoService: TodoServiceSpy
    let widgetSyncEventBus: WidgetSyncEventBusSpy
}

private actor TodoServiceSpy: TodoService {
    private var shouldFail = false

    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursorDTO?) async throws -> TodoPageResponse {
        throw TodoRepositoryImplTestsError.unexpectedCall
    }

    func upsertTodo(request: TodoRequest) async throws {
        guard shouldFail == false else {
            throw TodoRepositoryImplTestsError.serviceFailed
        }
    }

    func deleteTodo(todoId: String) async throws {
        guard shouldFail == false else {
            throw TodoRepositoryImplTestsError.serviceFailed
        }
    }

    func undoDeleteTodo(todoId: String) async throws {
        guard shouldFail == false else {
            throw TodoRepositoryImplTestsError.serviceFailed
        }
    }

    func fetchTodo(todoId: String) async throws -> TodoResponse {
        throw TodoRepositoryImplTestsError.unexpectedCall
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReferenceResponse] {
        throw TodoRepositoryImplTestsError.unexpectedCall
    }
}

private struct TodoCategoryServiceSpy: TodoCategoryService {
    func fetchPreferences() async throws -> [TodoCategoryPreferenceResponse] {
        []
    }

    func updatePreferences(_ preferences: [TodoCategoryPreferenceResponse]) async throws {
        throw TodoRepositoryImplTestsError.unexpectedCall
    }
}

private final class WidgetSyncEventBusSpy: WidgetSyncEventBus {
    private(set) var events = [WidgetSyncEvent]()

    func observe() -> AnyPublisher<WidgetSyncEvent, Never> {
        Empty().eraseToAnyPublisher()
    }

    func publish(_ event: WidgetSyncEvent) {
        events.append(event)
    }
}

private enum TodoRepositoryImplTestsError: Error, Equatable {
    case serviceFailed
    case unexpectedCall
}
