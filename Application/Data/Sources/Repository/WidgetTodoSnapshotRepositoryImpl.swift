//
//  WidgetTodoSnapshotRepositoryImpl.swift
//  Data
//
//  Created by opfic on 6/8/26.
//

import Foundation
import Core
import Domain

final class WidgetTodoSnapshotRepositoryImpl: WidgetTodoSnapshotRepository {
    private enum Key {
        static let preferences = "TodoCategory.preferences"
    }

    private let queryService: TodoQueryService
    private let todoCategoryService: TodoCategoryService
    private let store: MemoryCacheStore

    init(
        queryService: TodoQueryService,
        todoCategoryService: TodoCategoryService,
        store: MemoryCacheStore
    ) {
        self.queryService = queryService
        self.todoCategoryService = todoCategoryService
        self.store = store
    }

    func fetchTodayTodos(
        dueDateFilter: TodoQuery.DueDateFilter,
        sortTarget: TodoQuery.SortTarget,
        sortOrder: TodoQuery.SortOrder,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot] {
        let query = TodoQuery(
            completionFilter: .incomplete,
            dueDateFilter: dueDateFilter,
            sortTarget: sortTarget,
            sortOrder: sortOrder,
            pageSize: pageSize,
            fetchAllPages: true
        )

        do {
            async let todoPage = queryService.fetchTodos(query, cursor: nil)
            async let preferences = categoryPreferences()
            let (page, categoryPreferences) = try await (todoPage, preferences)
            let colors = userCategoryColors(from: categoryPreferences)
            return page.items.map { WidgetTodoSnapshot.fromResponse($0, userCategoryColors: colors) }
        } catch {
            throw error.toDomain()
        }
    }

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date,
        pageSize: Int
    ) async throws -> [WidgetTodoSnapshot] {
        let query = TodoQuery(
            sortDateFrom: quarterStart,
            sortDateTo: nextQuarterStart,
            includesDeleted: true,
            sortTarget: sortTarget,
            pageSize: pageSize,
            fetchAllPages: true
        )

        do {
            let todoPage = try await queryService.fetchTodos(query, cursor: nil)
            return todoPage.items.map { WidgetTodoSnapshot.fromResponse($0, userCategoryColors: [:]) }
        } catch {
            throw error.toDomain()
        }
    }
}

private extension WidgetTodoSnapshotRepositoryImpl {
    func categoryPreferences() async -> [TodoCategoryPreferenceResponse] {
        if let preferences = store.value(forKey: Key.preferences) as [TodoCategoryPreferenceResponse]? {
            return preferences
        }

        guard let preferences = try? await todoCategoryService.fetchCategoryPreferences() else {
            return []
        }
        store.setValue(preferences, forKey: Key.preferences)
        return preferences
    }

    func userCategoryColors(from preferences: [TodoCategoryPreferenceResponse]) -> [String: String] {
        var colors = [String: String]()
        for preference in preferences {
            guard case .user(let category) = preference.category else { continue }
            colors[category.id] = category.colorHex
        }
        return colors
    }
}

private extension WidgetTodoSnapshot {
    static func fromResponse(_ response: TodoResponse, userCategoryColors: [String: String]) -> Self {
        let categoryID: String
        let categoryColorHex: String?
        switch response.category {
        case .raw(let id):
            categoryID = id
            categoryColorHex = userCategoryColors[id]
        case .decoded(let category):
            categoryID = category.storageValue
            if case .user(let userCategory) = category {
                categoryColorHex = userCategory.colorHex
            } else {
                categoryColorHex = nil
            }
        }

        return WidgetTodoSnapshot(
            id: response.id,
            number: response.number,
            title: response.title,
            categoryID: categoryID,
            categoryColorHex: categoryColorHex,
            isPinned: response.isPinned,
            createdAt: response.createdAt,
            completedAt: response.completedAt,
            deletedAt: response.deletedAt,
            dueDate: response.dueDate
        )
    }
}
