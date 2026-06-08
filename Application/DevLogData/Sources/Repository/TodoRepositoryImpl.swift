//
//  TodoRepositoryImpl.swift
//  DevLogData
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation
import DevLogCore
import DevLogDomain

final class TodoRepositoryImpl: TodoRepository {
    private enum Key {
        static let preferences = "TodoCategory.preferences"
    }

    private let todoService: TodoService
    private let todoCategoryService: TodoCategoryService
    private let store: UserDefaultsStore
    private let widgetSyncEventBus: WidgetSyncEventBus
    private let todoMutationEventBus: TodoMutationEventBus

    init(
        todoService: TodoService,
        todoCategoryService: TodoCategoryService,
        store: UserDefaultsStore,
        widgetSyncEventBus: WidgetSyncEventBus,
        todoMutationEventBus: TodoMutationEventBus
    ) {
        self.todoService = todoService
        self.todoCategoryService = todoCategoryService
        self.store = store
        self.widgetSyncEventBus = widgetSyncEventBus
        self.todoMutationEventBus = todoMutationEventBus
    }

    func fetchTodos(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        let responseCursor = cursor.map { TodoCursorDTO.fromDomain($0) }

        do {
            async let todos = todoService.fetchTodos(query, cursor: responseCursor)
            async let preferences = todoCategoryPreferenceResponses()

            let (todoResponse, todoPreferenceResponses) = try await (
                todos,
                preferences
            )
            let userTodoCategories: [UserTodoCategory] = todoPreferenceResponses
                .toDomain()
                .compactMap { preference in
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
        } catch {
            throw error.toDomain()
        }
    }

    func fetchTodo(_ todoId: String) async throws -> Todo {
        do {
            async let response = todoService.fetchTodo(todoId: todoId)
            async let preferences = todoCategoryPreferenceResponses()

            let (todoResponse, todoPreferenceResponses) = try await (
                response,
                preferences
            )
            let userTodoCategories: [UserTodoCategory] = todoPreferenceResponses
                .toDomain()
                .compactMap { preference in
                guard case .user(let category) = preference.category else {
                    return nil
                }

                return category
            }

            return try resolve(todoResponse, userTodoCategories: userTodoCategories).toDomain()
        } catch {
            throw error.toDomain()
        }
    }

    func fetchReferences(_ numbers: [Int]) async throws -> [Int: TodoReference] {
        do {
            async let responseTask = todoService.fetchReferences(numbers)
            async let preferencesTask = todoCategoryPreferenceResponses()

            let (responses, preferenceResponses) = try await (
                responseTask,
                preferencesTask
            )
            let userTodoCategories: [UserTodoCategory] = preferenceResponses
                .toDomain()
                .compactMap { preference in
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
        } catch {
            throw error.toDomain()
        }
    }
    
    func upsertTodo(_ todo: Todo) async throws {
        let todoRequest = TodoRequest.fromDomain(todo)
        try await upsertTodo(todoRequest)
        todoMutationEventBus.publish(.updated(todo.id))
    }

    func upsertTodo(_ todoDraft: TodoDraft) async throws {
        let todoRequest = TodoRequest.fromDomain(todoDraft)
        try await upsertTodo(todoRequest)
    }

    private func upsertTodo(_ todoRequest: TodoRequest) async throws {
        do {
            try await todoService.upsertTodo(request: todoRequest)
            widgetSyncEventBus.publish(.syncRequested)
        } catch {
            throw error.toDomain()
        }
    }
    
    func deleteTodo(_ todoId: String) async throws {
        do {
            try await todoService.deleteTodo(todoId: todoId)
            widgetSyncEventBus.publish(.syncRequested)
            todoMutationEventBus.publish(.deleted(todoId))
        } catch {
            throw error.toDomain()
        }
    }

    func undoDeleteTodo(_ todoId: String) async throws {
        do {
            try await todoService.undoDeleteTodo(todoId: todoId)
            widgetSyncEventBus.publish(.syncRequested)
            todoMutationEventBus.publish(.restored(todoId))
        } catch {
            throw error.toDomain()
        }
    }
}

private extension TodoRepositoryImpl {
    func todoCategoryPreferenceResponses() async throws -> [TodoCategoryPreferenceResponse] {
        if let preferences: [TodoCategoryPreferenceResponse] = store.value(forKey: Key.preferences) {
            return preferences
        }

        let preferences = try await todoCategoryService.fetchCategoryPreferences()
        store.setValue(preferences, forKey: Key.preferences)
        return preferences
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
        let categoryId: String
        switch response.category {
        case .raw(let value):
            categoryId = value
        case .decoded:
            return response
        }

        let category: TodoCategory
        if let systemTodoCategory = SystemTodoCategory(rawValue: categoryId) {
            category = .system(systemTodoCategory)
        } else if let userTodoCategory = userTodoCategories.first(where: {
            $0.id == categoryId
        }) {
            category = .user(userTodoCategory)
        } else {
            throw DataError.invalidData("TodoReferenceResponse.category is invalid: \(categoryId)")
        }

        return TodoReferenceResponse(
            id: response.id,
            number: response.number,
            title: response.title,
            category: .decoded(category)
        )
    }
}
