//
//  TodoMapping.swift
//  Data
//
//  Created by 최윤진 on 2/19/26.
//

import Core
import Domain

public extension TodoRequest {
    static func fromDomain(_ todo: Todo) -> Self {
        TodoRequest(
            id: todo.id,
            isPinned: todo.isPinned,
            isCompleted: todo.isCompleted,
            isChecked: todo.isChecked,
            title: todo.title,
            content: todo.content,
            createdAt: todo.createdAt,
            updatedAt: todo.updatedAt,
            completedAt: todo.completedAt,
            deletedAt: todo.deletedAt,
            dueDate: todo.dueDate,
            tags: todo.tags,
            category: todo.category.storageValue
        )
    }

    static func fromDomain(_ todoDraft: TodoDraft) -> Self {
        TodoRequest(
            id: todoDraft.id,
            isPinned: todoDraft.isPinned,
            isCompleted: todoDraft.isCompleted,
            isChecked: todoDraft.isChecked,
            title: todoDraft.title,
            content: todoDraft.content,
            createdAt: todoDraft.createdAt,
            updatedAt: todoDraft.updatedAt,
            completedAt: todoDraft.completedAt,
            deletedAt: nil,
            dueDate: todoDraft.dueDate,
            tags: todoDraft.tags,
            category: todoDraft.category.storageValue
        )
    }
}

public extension TodoResponse {
    func toDomain() throws -> Todo {
        let todoCategory: TodoCategory

        switch category {
        case .decoded(let category):
            todoCategory = category
        case .raw(let category):
            throw DataError.invalidData("TodoResponse.category must be resolved before toDomain(): \(category)")
        }

        return Todo(
            id: id,
            isPinned: self.isPinned,
            isCompleted: self.isCompleted,
            isChecked: self.isChecked,
            number: self.number,
            title: self.title,
            content: self.content,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            completedAt: self.completedAt,
            deletedAt: self.deletedAt,
            dueDate: self.dueDate,
            tags: self.tags,
            category: todoCategory
        )
    }
}

public extension WidgetTodoSnapshot {
    static func fromDomain(_ todo: Todo) -> Self {
        WidgetTodoSnapshot(
            id: todo.id,
            number: todo.number,
            title: todo.title,
            isPinned: todo.isPinned,
            createdAt: todo.createdAt,
            completedAt: todo.completedAt,
            deletedAt: todo.deletedAt,
            dueDate: todo.dueDate
        )
    }

    static func fromDomain(_ draft: TodoDraft) -> Self {
        WidgetTodoSnapshot(
            id: draft.id,
            number: nil,
            title: draft.title,
            isPinned: draft.isPinned,
            createdAt: draft.createdAt,
            completedAt: draft.completedAt,
            deletedAt: nil,
            dueDate: draft.dueDate
        )
    }
}

public extension TodoCursorDTO {
    func toDomain() -> TodoCursor {
        TodoCursor(
            primarySortDate: primarySortDate,
            secondarySortDate: secondarySortDate,
            documentID: documentID
        )
    }

    static func fromDomain(_ cursor: TodoCursor) -> Self {
        TodoCursorDTO(
            primarySortDate: cursor.primarySortDate,
            secondarySortDate: cursor.secondarySortDate,
            documentID: cursor.documentID
        )
    }
}

public extension TodoPageResponse {
    func toDomain() throws -> TodoPage {
        let items = try items.map { try $0.toDomain() }
        let cursor = nextCursor?.toDomain()
        return TodoPage(items: items, nextCursor: cursor)
    }
}
