//
//  TodoMapping.swift
//  DevLog
//
//  Created by 최윤진 on 2/19/26.
//

extension TodoRequest {
    static func fromDomain(_ entity: Todo) -> Self {
        TodoRequest(
            id: entity.id,
            isPinned: entity.isPinned,
            isCompleted: entity.isCompleted,
            isChecked: entity.isChecked,
            number: entity.number,
            title: entity.title,
            content: entity.content,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            completedAt: entity.completedAt,
            dueDate: entity.dueDate,
            tags: entity.tags,
            category: entity.category.storageValue
        )
    }
}

extension TodoResponse {
    func toDomain() throws -> Todo {
        guard let category = SystemTodoCategory(rawValue: self.category) else {
            throw DataError.invalidData("TodoResponse.category is invalid: \(self.category)")
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
            dueDate: self.dueDate,
            tags: self.tags,
            category: .system(category)
        )
    }
}

extension TodoCursorDTO {
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

extension TodoPageResponse {
    func toDomain() throws -> TodoPage {
        let items = try items.map { try $0.toDomain() }
        let cursor = nextCursor?.toDomain()
        return TodoPage(items: items, nextCursor: cursor)
    }
}
