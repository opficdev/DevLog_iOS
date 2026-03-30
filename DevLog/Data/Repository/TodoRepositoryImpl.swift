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

    init(
        todoService: TodoService,
        todoCategoryService: TodoCategoryService
    ) {
        self.todoService = todoService
        self.todoCategoryService = todoCategoryService
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

    func fetchReferenceItems(_ numbers: [Int]) async throws -> [Int: TodoReferenceItem] {
        try await todoService.fetchReferenceItems(numbers)
    }
    
    func upsertTodo(_ todo: Todo) async throws {
        let request = TodoRequest.fromDomain(todo)
        try await todoService.upsertTodo(request: request)
    }
    
    func deleteTodo(_ todoId: String) async throws {
        try await todoService.deleteTodo(todoId: todoId)
    }

    func undoDeleteTodo(_ todoId: String) async throws {
        try await todoService.undoDeleteTodo(todoId: todoId)
    }
}

private extension TodoRepositoryImpl {
    func resolve(
        _ response: TodoResponse,
        userTodoCategories: [UserTodoCategory]
    ) throws -> TodoResponse {
        let categoryName: String
        switch response.category {
        case .raw(let value):
            categoryName = value
        case .decoded:
            return response
        }

        let category: TodoCategory
        if let systemTodoCategory = SystemTodoCategory(rawValue: categoryName) {
            category = .system(systemTodoCategory)
        } else if let userTodoCategory = userTodoCategories.first(where: {
            $0.name == categoryName
        }) {
            category = .user(userTodoCategory)
        } else {
            throw DataError.invalidData("TodoResponse.category is invalid: \(categoryName)")
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
            dueDate: response.dueDate,
            tags: response.tags,
            category: .decoded(category)
        )
    }
}
