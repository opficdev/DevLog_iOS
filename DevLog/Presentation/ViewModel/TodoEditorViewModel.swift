//
//  TodoEditorViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/24/25.
//

import Foundation
import OrderedCollections

@Observable
final class TodoEditorViewModel: Store {
    private struct Draft: Equatable {
        let title: String
        let content: String
        let dueDate: Date?
        let tags: [String]

        init(todo: Todo) {
            self.title = todo.title
            self.content = todo.content
            self.dueDate = todo.dueDate
            self.tags = todo.tags
        }

        init(state: State) {
            self.title = state.title
            self.content = state.content
            self.dueDate = state.dueDate
            self.tags = Array(state.tags)
        }
    }

    struct State: Equatable {
        var title: String = ""
        var content: String = ""
        var dueDate: Date?
        var tags: OrderedSet<String> = []
        var tagText: String = ""
        var focusOnEditor: Bool = false
        var hasDueDate: Bool { dueDate != nil }
        var tabViewTag: Tag = .editor
        var isValidToSave: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Tag {
        case editor, preview
    }

    enum Action {
        case addTag(String)
        case removeTag(String)
        case setContent(String)
        case setDueDate(Date?)
        case setTabViewTag(Tag)
        case setTagText(String)
        case setTitle(String)
        case toggleDueDate
    }

    enum SideEffect { }

    private(set) var state = State()
    private let calendar = Calendar.current
    let navigationTitle: String
    private let id: String
    private let isPinned: Bool
    private let isCompleted: Bool
    private let isChecked: Bool
    private let createdAt: Date?
    private let completedAt: Date?
    private let kind: TodoKind
    private let originalDraft: Draft?

    var hasChanges: Bool {
        guard let originalDraft else { return true }
        return originalDraft != Draft(state: state)
    }

    var isReadyToSubmit: Bool {
        state.isValidToSave && hasChanges
    }

    // 새로운 Todo 생성용 생성자
    init(kind: TodoKind) {
        self.navigationTitle = "새 \(kind.localizedName) 추가"
        self.id = UUID().uuidString
        self.isPinned = false
        self.isCompleted = false
        self.isChecked = false
        self.createdAt = nil
        self.completedAt = nil
        self.kind = kind
        self.originalDraft = nil
    }

    // 기존 Todo 편집용 생성자
    init(todo: Todo) {
        self.navigationTitle = "편집"
        self.id = todo.id
        self.isPinned = todo.isPinned
        self.isCompleted = todo.isCompleted
        self.isChecked = todo.isChecked
        self.createdAt = todo.createdAt
        self.completedAt = todo.completedAt
        self.kind = todo.kind
        self.originalDraft = Draft(todo: todo)
        state.title = todo.title
        state.content = todo.content
        state.dueDate = todo.dueDate
        state.tags = OrderedSet(todo.tags)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .addTag(let tag):
            if !tag.isEmpty {
                state.tags.append(tag)
            }
        case .removeTag(let tagText):
            state.tags.removeAll { $0 == tagText }
        case .setContent(let stringValue),
             .setTagText(let stringValue),
             .setTitle(let stringValue):
            handleStringAction(action, stringValue: stringValue, state: &state)
        case .setDueDate(let dueDate):
            if let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: Date()), let dueDate {
                state.dueDate = max(dueDate, tomorrowDate)
            } else {
                state.dueDate = nil
            }
        case .setTabViewTag(let tag):
            state.tabViewTag = tag
        case .toggleDueDate:
            if state.hasDueDate {
                state.dueDate = nil
            } else {
                state.dueDate = calendar.date(byAdding: .day, value: 1, to: Date())
            }
        }

        if self.state != state { self.state = state }
        return []
    }
}

extension TodoEditorViewModel {
    private func handleStringAction(
        _ action: Action,
        stringValue: String,
        state: inout State
    ) {
        switch action {
        case .setContent:
            state.content = stringValue
        case .setTagText:
            state.tagText = stringValue
        case .setTitle:
            state.title = stringValue
        default:
            break
        }
    }

    func makeTodo() -> Todo {
        let date = Date()
        return Todo(
            id: self.id,
            isPinned: self.isPinned,
            isCompleted: self.isCompleted,
            isChecked: self.isChecked,
            title: state.title,
            content: state.content,
            createdAt: self.createdAt ?? date,
            updatedAt: date,
            completedAt: self.completedAt,
            dueDate: state.dueDate,
            tags: state.tags.map { $0 },
            kind: self.kind
        )
    }
}
