//
//  TodoEditorWindowValue.swift
//  Presentation
//
//  Created by opfic on 5/31/26.
//

import Foundation
import Domain

public enum TodoEditorWindowValue: Codable, Hashable {
    case create(TodoEditorWindowCategory, TodoEditorWindowSource)
    case edit(TodoEditorWindowTodo)

    public static let sceneId = "todo-editor"

    public init(
        todoCategory: TodoCategory,
        source: TodoEditorWindowSource
    ) {
        self = .create(TodoEditorWindowCategory(todoCategory: todoCategory), source)
    }

    init(todo: Todo) {
        self = .edit(TodoEditorWindowTodo(todo: todo))
    }
}

public enum TodoEditorWindowSource: String, Codable, Hashable {
    case home
    case list
}

public struct TodoEditorWindowCategory: Codable, Hashable {
    private enum Kind: String, Codable {
        case system
        case user
    }

    private let kind: Kind
    private let id: String
    private let name: String
    private let colorHex: String

    init(todoCategory: TodoCategory) {
        switch todoCategory {
        case .system(let systemTodoCategory):
            self.kind = .system
            self.id = systemTodoCategory.rawValue
            self.name = ""
            self.colorHex = ""
        case .user(let userTodoCategory):
            self.kind = .user
            self.id = userTodoCategory.id
            self.name = userTodoCategory.name
            self.colorHex = userTodoCategory.colorHex
        }
    }

    var todoCategory: TodoCategory {
        switch kind {
        case .system:
            let systemTodoCategory = SystemTodoCategory(rawValue: id) ?? .etc
            return .system(systemTodoCategory)
        case .user:
            return .user(UserTodoCategory(
                id: id,
                name: name,
                colorHex: colorHex
            ))
        }
    }
}

public struct TodoEditorWindowTodo: Codable, Hashable {
    private let id: String
    private let isPinned: Bool
    private let isCompleted: Bool
    private let isChecked: Bool
    private let number: Int
    private let title: String
    private let content: String
    private let createdAt: Date
    private let updatedAt: Date
    private let completedAt: Date?
    private let deletedAt: Date?
    private let dueDate: Date?
    private let tags: [String]
    private let category: TodoEditorWindowCategory

    init(todo: Todo) {
        self.id = todo.id
        self.isPinned = todo.isPinned
        self.isCompleted = todo.isCompleted
        self.isChecked = todo.isChecked
        self.number = todo.number
        self.title = todo.title
        self.content = todo.content
        self.createdAt = todo.createdAt
        self.updatedAt = todo.updatedAt
        self.completedAt = todo.completedAt
        self.deletedAt = todo.deletedAt
        self.dueDate = todo.dueDate
        self.tags = todo.tags
        self.category = TodoEditorWindowCategory(todoCategory: todo.category)
    }

    public static func == (
        lhs: TodoEditorWindowTodo,
        rhs: TodoEditorWindowTodo
    ) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var todo: Todo {
        Todo(
            id: id,
            isPinned: isPinned,
            isCompleted: isCompleted,
            isChecked: isChecked,
            number: number,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: dueDate,
            tags: tags,
            category: category.todoCategory
        )
    }
}

enum TodoEditorWindowSubmit: Equatable {
    case create(TodoEditorWindowValue)
    case update(TodoEditorWindowValue, Todo)
}

extension TodoEditorWindowValue {
    func matchesCreate(
        category: TodoCategory? = nil,
        source: TodoEditorWindowSource
    ) -> Bool {
        guard case .create(let windowCategory, let windowSource) = self,
              windowSource == source else { return false }
        if let category {
            return windowCategory.todoCategory == category
        }
        return true
    }

    func matchesEdit(todoId: String) -> Bool {
        guard case .edit(let windowTodo) = self else { return false }
        return windowTodo.todo.id == todoId
    }
}
