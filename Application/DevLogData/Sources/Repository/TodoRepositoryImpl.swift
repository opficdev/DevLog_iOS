//
//  TodoRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation
import DevLogDomain

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
