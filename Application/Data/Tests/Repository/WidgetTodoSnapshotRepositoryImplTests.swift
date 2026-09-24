//
//  WidgetTodoSnapshotRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 8/28/26.
//

import Testing
import Core
@testable import Data

struct WidgetTodoSnapshotRepositoryImplTests {
    @Test("Widget 오늘 Todo 조회는 Query service에만 전달한다")
    func Widget_오늘_Todo_조회는_Query_service에만_전달한다() async throws {
        let queryService = TodoRepositoryQueryServiceSpy()
        let repository = WidgetTodoSnapshotRepositoryImpl(
            queryService: queryService,
            todoCategoryService: WidgetTodoCategoryServiceSpy(),
            store: WidgetTodoMemoryCacheStoreSpy()
        )

        let snapshots = try await repository.fetchTodayTodos(
            dueDateFilter: .withDueDate,
            sortTarget: .dueDate,
            sortOrder: .latest,
            pageSize: 10
        )

        let query = try #require(await queryService.fetchTodoQueries().first)
        #expect(snapshots.map(\.id) == ["todo-1"])
        #expect(snapshots.map(\.categoryID) == ["feature"])
        #expect(query.completionFilter == .incomplete)
        #expect(query.dueDateFilter == .withDueDate)
        #expect(query.fetchAllPages)
    }

    @Test("Widget 오늘 Todo 스냅샷에 사용자 카테고리 색상을 전달한다")
    func Widget_오늘_Todo_스냅샷에_사용자_카테고리_색상을_전달한다() async throws {
        let repository = WidgetTodoSnapshotRepositoryImpl(
            queryService: WidgetTodoQueryServiceSpy(),
            todoCategoryService: WidgetTodoCategoryServiceSpy(
                preferences: [
                    TodoCategoryPreferenceResponse(
                        category: .user(.init(id: "custom", name: "사용자", colorHex: "#AABBCC")),
                        isVisible: true
                    )
                ]
            ),
            store: WidgetTodoMemoryCacheStoreSpy()
        )

        let snapshots = try await repository.fetchTodayTodos(
            dueDateFilter: .withDueDate,
            sortTarget: .dueDate,
            sortOrder: .latest,
            pageSize: 10
        )

        #expect(snapshots.first?.categoryID == "custom")
        #expect(snapshots.first?.categoryColorHex == "#AABBCC")
    }
}

private actor WidgetTodoQueryServiceSpy: TodoQueryService {
    func fetchTodos(_ query: TodoQuery, cursor: TodoCursorDTO?) async throws -> TodoPageResponse {
        let response = TodoResponse(
            id: "todo-custom",
            isPinned: false,
            isCompleted: false,
            isChecked: false,
            number: 1,
            title: "사용자 Todo",
            content: "",
            createdAt: .distantPast,
            updatedAt: .distantPast,
            completedAt: nil,
            deletedAt: nil,
            dueDate: nil,
            tags: [],
            category: .raw("custom")
        )
        return TodoPageResponse(items: [response], nextCursor: nil)
    }

    func fetchTodo(todoId: String) async throws -> TodoResponse {
        throw DataLayerError.invalidData(todoId)
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReferenceResponse] {
        [:]
    }
}

private actor WidgetTodoCategoryServiceSpy: TodoCategoryService {
    let preferences: [TodoCategoryPreferenceResponse]

    init(preferences: [TodoCategoryPreferenceResponse] = []) {
        self.preferences = preferences
    }

    func fetchCategoryPreferences() async throws -> [TodoCategoryPreferenceResponse] {
        preferences
    }

    func updateCategoryPreferences(_ preferences: [TodoCategoryPreferenceResponse]) async throws { }
}

private final class WidgetTodoMemoryCacheStoreSpy: MemoryCacheStore {
    func value<T: Codable>(forKey key: String) -> T? { nil }
    func setValue<T: Codable>(_ value: T?, forKey key: String) { }
}
