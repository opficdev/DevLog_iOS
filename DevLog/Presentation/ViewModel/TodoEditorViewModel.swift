//
//  TodoEditorViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/24/25.
//

import Foundation

final class TodoEditorViewModel: Store {
    struct State {
        var title: String = ""
        var content: String = ""
        var dueDate: Date?
        var tags: [String] = []
        var tagText: String = ""
        var focusOnEditor: Bool = false
        var hasDueDate: Bool { return dueDate != nil }
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
        case addTag
        case removeTag(String)
        case setContent(String)
        case setDueDate(Date)
        case setTabViewTag(Tag)
        case setTagText(String)
        case setTitle(String)
        case toggleDueDate
    }

    enum SideEffect { }

    @Published private(set) var state = State()
    private let calendar = Calendar.current
    let navigationTitle: String
    private let id: String
    private let isPinned: Bool
    private let isCompleted: Bool
    private let isChecked: Bool
    private let createdAt: Date?
    private let kind: TodoKind

    init(title: String, todo: Todo? = nil) {
        self.navigationTitle = title
        self.id = todo?.id ?? UUID().uuidString
        self.isPinned = todo?.isPinned ?? false
        self.isCompleted = todo?.isCompleted ?? false
        self.isChecked = todo?.isChecked ?? false
        self.createdAt = todo?.createdAt ?? nil
        self.kind = todo?.kind ?? .etc
        if let todo {
            state.title = todo.title
            state.content = todo.content
            state.dueDate = todo.dueDate
            state.tags = todo.tags
        }
    }

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .addTag:
            let tagText = state.tagText
            if !state.tags.contains(tagText) && !tagText.isEmpty {
                state.tags.append(tagText)
                state.tagText = ""
            }
        case .removeTag(let tagText):
            state.tags.removeAll { $0 == tagText }
        case .setContent(let stringValue),
             .setTagText(let stringValue),
             .setTitle(let stringValue):
            handleStringAction(action, stringValue: stringValue)
        case .setDueDate(let dueDate):
            if let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: Date()) {
                state.dueDate = max(dueDate, tomorrowDate)
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
        return []
    }

    func run(_ effect: SideEffect) { }
}

extension TodoEditorViewModel {
    private func handleStringAction(_ action: Action, stringValue: String) {
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

    func upsertTodo() -> Todo {
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
            dueDate: state.dueDate,
            tags: state.tags,
            kind: self.kind
        )
    }
}
