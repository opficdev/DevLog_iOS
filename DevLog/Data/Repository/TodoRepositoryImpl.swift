//
//  TodoRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation

final class TodoRepositoryImpl: TodoRepository {
    private let todoService: TodoService
    private let todoCategoryService: TodoCategoryService
    private let widgetSnapshotUpdater: WidgetSnapshotUpdater
    private let calendar = Calendar.current
    private let pageSize = 100
    private let logger = Logger(category: "TodoRepositoryImpl")

    init(
        todoService: TodoService,
        todoCategoryService: TodoCategoryService,
        widgetSnapshotUpdater: WidgetSnapshotUpdater
    ) {
        self.todoService = todoService
        self.todoCategoryService = todoCategoryService
        self.widgetSnapshotUpdater = widgetSnapshotUpdater
    }

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        let responseCursor = cursor.map { TodoCursorDTO.fromDomain($0) }
        async let response = todoService.fetchTodos(query, cursor: responseCursor)
        async let preferences = todoCategoryService.fetchPreferences()

        let (todoResponse, todoPreferences) = try await (response, preferences)
        let userTodoCategories: [UserTodoCategory] = todoPreferences.compactMap { preference in
            guard case .user(let category) = preference.category else {
                return nil
            }

            return category
        }

        let resolvedTodoResponses = try todoResponse.items.map {
            try resolve($0, userTodoCategories: userTodoCategories)
        }

        return try TodoPageResponse(
            items: resolvedTodoResponses,
            nextCursor: todoResponse.nextCursor
        ).toDomain()
    }

    func fetchTodo(_ todoId: String) async throws -> Todo {
        async let response = todoService.fetchTodo(todoId: todoId)
        async let preferences = todoCategoryService.fetchPreferences()

        let (todoResponse, todoPreferences) = try await (response, preferences)
        let userTodoCategories: [UserTodoCategory] = todoPreferences.compactMap { preference in
            guard case .user(let category) = preference.category else {
                return nil
            }

            return category
        }

        return try resolve(todoResponse, userTodoCategories: userTodoCategories).toDomain()
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReference] {
        async let responseTask = todoService.fetchReferences(numbers)
        async let preferencesTask = todoCategoryService.fetchPreferences()

        let (responses, preferences) = try await (responseTask, preferencesTask)
        let userTodoCategories: [UserTodoCategory] = preferences.compactMap { preference in
            guard case .user(let category) = preference.category else {
                return nil
            }

            return category
        }

        return try responses.reduce(into: [Int: TodoReference]()) { partialResult, pair in
            let response = try resolve(pair.value, userTodoCategories: userTodoCategories)
            guard case let .decoded(category) = response.category else {
                throw DataError.invalidData("TodoReferenceResponse.category must be resolved before use")
            }

            partialResult[pair.key] = TodoReference(
                id: response.id,
                title: response.title,
                category: category
            )
        }
    }
    
    func upsertTodo(_ todo: Todo) async throws {
        let request = TodoRequest.fromDomain(todo)
        try await todoService.upsertTodo(request: request)
        updateWidgetSnapshots()
    }
    
    func deleteTodo(_ todoId: String) async throws {
        try await todoService.deleteTodo(todoId: todoId)
        updateWidgetSnapshots()
    }

    func undoDeleteTodo(_ todoId: String) async throws {
        try await todoService.undoDeleteTodo(todoId: todoId)
        updateWidgetSnapshots()
    }
}

private extension TodoRepositoryImpl {
    func updateWidgetSnapshots() {
        Task { [weak self] in
            guard let self else { return }
            async let todaySnapshot: Void = updateTodayWidgetSnapshot()
            async let heatmapSnapshot: Void = updateHeatmapWidgetSnapshot()
            _ = await (todaySnapshot, heatmapSnapshot)
        }
    }

    func updateTodayWidgetSnapshot() async {
        do {
            async let todosWithDueDate = fetchTodayTodos(
                dueDateFilter: .withDueDate,
                sortTarget: .dueDate,
                sortOrder: .oldest
            )
            async let todosWithoutDueDate = fetchTodayTodos(
                dueDateFilter: .withoutDueDate,
                sortTarget: .updatedAt,
                sortOrder: .latest
            )
            let (todayTodosWithDueDate, todayTodosWithoutDueDate) = try await (
                todosWithDueDate,
                todosWithoutDueDate
            )
            widgetSnapshotUpdater.updateTodaySnapshot(
                todos: todayTodosWithDueDate + todayTodosWithoutDueDate
            )
        } catch {
            logger.error(
                "Failed to fetch today widget snapshot data.",
                error: error
            )
        }
    }

    func updateHeatmapWidgetSnapshot() async {
        let now = Date()
        let quarterStart = widgetSnapshotUpdater.startOfQuarter(for: now)
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
            return
        }

        do {
            async let createdTodos = fetchHeatmapTodos(
                sortTarget: .createdAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart
            )
            async let completedTodos = fetchHeatmapTodos(
                sortTarget: .completedAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart
            )
            async let deletedTodos = fetchHeatmapTodos(
                sortTarget: .deletedAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart
            )
            let (createdTodoItems, completedTodoItems, deletedTodoItems) = try await (
                createdTodos,
                completedTodos,
                deletedTodos
            )
            widgetSnapshotUpdater.updateHeatmapSnapshot(
                createdTodos: createdTodoItems,
                completedTodos: completedTodoItems,
                deletedTodos: deletedTodoItems,
                quarterStart: quarterStart,
                now: now
            )
        } catch {
            logger.error(
                "Failed to fetch heatmap widget snapshot data.",
                error: error
            )
        }
    }

    func fetchTodayTodos(
        dueDateFilter: TodoQuery.DueDateFilter,
        sortTarget: TodoQuery.SortTarget,
        sortOrder: TodoQuery.SortOrder
    ) async throws -> [TodayTodoItem] {
        let todoPage = try await fetchTodos(
            TodoQuery(
                completionFilter: .incomplete,
                dueDateFilter: dueDateFilter,
                sortTarget: sortTarget,
                sortOrder: sortOrder,
                pageSize: pageSize,
                fetchAllPages: true
            ),
            cursor: nil
        )

        return todoPage.items.compactMap { TodayTodoItem(from: $0) }
    }

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date
    ) async throws -> [Todo] {
        let todoPage = try await fetchTodos(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: sortTarget,
                pageSize: pageSize,
                fetchAllPages: true
            ),
            cursor: nil
        )

        return todoPage.items
    }

    func resolve(
        _ response: TodoResponse,
        userTodoCategories: [UserTodoCategory]
    ) throws -> TodoResponse {
        let id: String
        switch response.category {
        case .raw(let value):
            id = value
        case .decoded:
            return response
        }

        let category: TodoCategory
        if let systemTodoCategory = SystemTodoCategory(rawValue: id) {
            category = .system(systemTodoCategory)
        } else if let userTodoCategory = userTodoCategories.first(where: {
            $0.id == id
        }) {
            category = .user(userTodoCategory)
        } else {
            throw DataError.invalidData("TodoResponse.category is invalid: \(id)")
        }

        return TodoResponse(
            id: response.id,
            isPinned: response.isPinned,
            isCompleted: response.isCompleted,
            isChecked: response.isChecked,
            number: response.number,
            title: response.title,
            content: response.content,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt,
            completedAt: response.completedAt,
            deletedAt: response.deletedAt,
            dueDate: response.dueDate,
            tags: response.tags,
            category: .decoded(category)
        )
    }

    func resolve(
        _ response: TodoReferenceResponse,
        userTodoCategories: [UserTodoCategory]
    ) throws -> TodoReferenceResponse {
        let categoryID: String
        switch response.category {
        case .raw(let value):
            categoryID = value
        case .decoded:
            return response
        }

        let category: TodoCategory
        if let systemTodoCategory = SystemTodoCategory(rawValue: categoryID) {
            category = .system(systemTodoCategory)
        } else if let userTodoCategory = userTodoCategories.first(where: {
            $0.id == categoryID
        }) {
            category = .user(userTodoCategory)
        } else {
            throw DataError.invalidData("TodoReferenceResponse.category is invalid: \(categoryID)")
        }

        return TodoReferenceResponse(
            id: response.id,
            number: response.number,
            title: response.title,
            category: .decoded(category)
        )
    }
}
