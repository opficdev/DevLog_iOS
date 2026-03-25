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
        let isCompleted: Bool
        let completedAt: Date?
        let isPinned: Bool
        let title: String
        let content: String
        let dueDate: Date?
        let tags: [String]
        let kind: TodoKind

        init(todo: Todo) {
            self.isCompleted = todo.isCompleted
            self.completedAt = todo.completedAt
            self.isPinned = todo.isPinned
            self.title = todo.title
            self.content = todo.content
            self.dueDate = todo.dueDate
            self.tags = todo.tags
            self.kind = todo.kind
        }

        init(state: State) {
            self.isCompleted = state.isCompleted
            self.completedAt = state.completedAt
            self.isPinned = state.isPinned
            self.title = state.title
            self.content = state.content
            self.dueDate = state.dueDate
            self.tags = Array(state.tags)
            self.kind = state.kind
        }
    }

    struct State: Equatable {
        var isCompleted: Bool = false
        var completedAt: Date?
        var isPinned: Bool = false
        var title: String = ""
        var content: String = ""
        var dueDate: Date?
        var showInfo: Bool = false
        var tags: OrderedSet<String> = []
        var tagText: String = ""
        var focusOnEditor: Bool = false
        var tabViewTag: Tag = .editor
        var kind: TodoKind = .etc
        var isValidToSave: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Tag {
        case editor, preview
    }

    enum Action {
        case addTag(String)
        case removeTag(String)
        case setContent(String)
        case setCompleted(Bool)
        case setDueDate(Date?)
        case setKind(TodoKind)
        case setPinned(Bool)
        case setShowInfo(Bool)
        case setTabViewTag(Tag)
        case setTagText(String)
        case setTitle(String)
    }

    enum SideEffect { }

    private(set) var state = State()
    private let calendar = Calendar.current
    private let id: String
    private let isCompleted: Bool
    private let isChecked: Bool
    private let number: Int?
    private let createdAt: Date?
    private let originalDraft: Draft?

    var navigationTitle: String {
        if originalDraft == nil {
            return "새 \(state.kind.localizedName) 추가"
        }

        return "편집"
    }

    var hasChanges: Bool {
        guard let originalDraft else { return true }
        return originalDraft != Draft(state: state)
    }

    var isReadyToSubmit: Bool {
        state.isValidToSave && hasChanges
    }

    // 새로운 Todo 생성용 생성자
    init(kind: TodoKind) {
        self.id = UUID().uuidString
        self.isCompleted = false
        self.isChecked = false
        self.number = nil
        self.createdAt = nil
        self.originalDraft = nil
        state.kind = kind
    }

    // 기존 Todo 편집용 생성자
    init(todo: Todo) {
        self.id = todo.id
        self.isCompleted = todo.isCompleted
        self.isChecked = todo.isChecked
        self.number = todo.number
        self.createdAt = todo.createdAt
        self.originalDraft = Draft(todo: todo)
        state.isCompleted = todo.isCompleted
        state.completedAt = todo.completedAt
        state.isPinned = todo.isPinned
        state.title = todo.title
        state.content = todo.content
        state.dueDate = todo.dueDate
        state.tags = OrderedSet(todo.tags)
        state.kind = todo.kind
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
        case .setCompleted(let isCompleted):
            if state.isCompleted != isCompleted {
                state.completedAt = isCompleted ? Date() : nil
            }
            state.isCompleted = isCompleted
        case .setKind(let todoKind):
            state.kind = todoKind
        case .setPinned(let isPinned):
            state.isPinned = isPinned
        case .setShowInfo(let isPresented):
            state.showInfo = isPresented
        case .setTabViewTag(let tag):
            state.tabViewTag = tag
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
            isPinned: state.isPinned,
            isCompleted: state.isCompleted,
            isChecked: self.isChecked,
            number: self.number,
            title: state.title,
            content: state.content,
            createdAt: self.createdAt ?? date,
            updatedAt: date,
            completedAt: state.completedAt,
            dueDate: state.dueDate,
            tags: state.tags.map { $0 },
            kind: state.kind
        )
    }
}
