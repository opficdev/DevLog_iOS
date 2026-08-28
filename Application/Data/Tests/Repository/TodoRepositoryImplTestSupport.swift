//
//  TodoRepositoryImplTestSupport.swift
//  DataTests
//
//  Created by opfic on 8/28/26.
//

import Combine
import Foundation
import Core
import Domain
@testable import Data

actor TodoRepositoryQueryServiceSpy: TodoQueryService {
    private var recordedTodoQueries = [TodoQuery]()

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursorDTO?) async throws -> TodoPageResponse {
        recordedTodoQueries.append(query)
        return .init(items: [makeTodoRepositoryResponse()], nextCursor: nil)
    }

    func fetchTodo(todoId: String) async throws -> TodoResponse {
        makeTodoRepositoryResponse()
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReferenceResponse] {
        [:]
    }

    func fetchTodoQueries() -> [TodoQuery] {
        recordedTodoQueries
    }
}

actor TodoRepositoryCommandServiceSpy: TodoCommandService {
    private var recordedUpsertRequests = [TodoRequest]()

    func upsertTodo(request: TodoRequest) async throws {
        recordedUpsertRequests.append(request)
    }

    func deleteTodo(todoId: String) async throws { }

    func undoDeleteTodo(todoId: String) async throws { }

    func upsertRequests() -> [TodoRequest] {
        recordedUpsertRequests
    }
}

private actor TodoRepositoryCategoryServiceSpy: TodoCategoryService {
    func fetchCategoryPreferences() async throws -> [TodoCategoryPreferenceResponse] {
        []
    }

    func updateCategoryPreferences(_ preferences: [TodoCategoryPreferenceResponse]) async throws { }
}

private final class TodoRepositoryMemoryCacheStoreSpy: MemoryCacheStore {
    func value<T: Codable>(forKey key: String) -> T? {
        nil
    }

    func setValue<T: Codable>(_ value: T?, forKey key: String) { }
}

private final class TodoRepositoryWidgetSnapshotUpdaterSpy: WidgetSnapshotUpdater {
    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot]?,
        displayOptions: TodayDisplayOptions?,
        now: Date
    ) { }

    func updateHeatmapSnapshot(
        createdTodos: [WidgetTodoSnapshot]?,
        completedTodos: [WidgetTodoSnapshot]?,
        deletedTodos: [WidgetTodoSnapshot]?,
        quarterStart: Date?,
        now: Date
    ) { }

    func upsertTodoSnapshot(_ todo: WidgetTodoSnapshot, now: Date) { }

    func deleteTodoSnapshot(todoId: String, deletedAt: Date, now: Date) { }

    func restoreTodoSnapshot(todoId: String, now: Date) { }

    func clear() { }
}

private final class TodoRepositoryMutationEventBusSpy: TodoMutationEventBus {
    private let subject = PassthroughSubject<TodoMutationEvent, Never>()

    func publish(_ event: TodoMutationEvent) {
        subject.send(event)
    }

    func observe() -> AnyPublisher<TodoMutationEvent, Never> {
        subject.eraseToAnyPublisher()
    }
}

func makeTodoRepository(
    queryService: TodoQueryService,
    commandService: TodoCommandService
) -> TodoRepositoryImpl {
    TodoRepositoryImpl(
        queryService: queryService,
        commandService: commandService,
        todoCategoryService: TodoRepositoryCategoryServiceSpy(),
        store: TodoRepositoryMemoryCacheStoreSpy(),
        updater: TodoRepositoryWidgetSnapshotUpdaterSpy(),
        eventBus: TodoRepositoryMutationEventBusSpy()
    )
}

func makeTodoRepositoryTodo() -> Todo {
    Todo(
        id: "todo-1",
        isPinned: false,
        isCompleted: false,
        isChecked: false,
        number: 1,
        title: "Todo",
        content: "내용",
        createdAt: .distantPast,
        updatedAt: .distantPast,
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: .system(.feature)
    )
}

func makeTodoRepositoryResponse() -> TodoResponse {
    TodoResponse(
        id: "todo-1",
        isPinned: false,
        isCompleted: false,
        isChecked: false,
        number: 1,
        title: "Todo",
        content: "내용",
        createdAt: .distantPast,
        updatedAt: .distantPast,
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: .raw("feature")
    )
}
