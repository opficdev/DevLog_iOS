//
//  TodoMapping.swift
//  DevLog
//
//  Created by 최윤진 on 2/19/26.
//

import Foundation

extension TodoRequest {
    static func fromDomain(_ entity: Todo) -> Self {
        TodoRequest(
            id: entity.id,
            isPinned: entity.isPinned,
            isCompleted: entity.isCompleted,
            isChecked: entity.isChecked,
            title: entity.title,
            content: entity.content,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            dueDate: entity.dueDate,
            tags: entity.tags,
            kind: entity.kind
        )
    }
}

extension TodoResponse {
    func toDomain() throws -> Todo {
        guard let id = self.id else {
            throw DataError.invalidData("TodoResponse.id is nil")
        }
        guard let kind = TodoKind(rawValue: self.kind) else {
            throw DataError.invalidData("TodoResponse.kind is invalid: \(self.kind)")
        }

        return Todo(
            id: id,
            isPinned: self.isPinned,
            isCompleted: self.isCompleted,
            isChecked: self.isChecked,
            title: self.title,
            content: self.content,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            dueDate: self.dueDate,
            tags: self.tags,
            kind: kind
        )
    }
}
