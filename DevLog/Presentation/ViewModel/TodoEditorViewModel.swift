//
//  TodoEditorViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/24/25.
//

import Foundation

final class TodoEditorViewModel: Store {
    struct State {
        let calendar = Calendar.current
        let navigationTitle: String
        var title: String = ""
        var dueDate: Date?
        var content: String = ""
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

    enum SideEffect {

    }

    @Published private(set) var state: State

    init(title: String, todo: Todo? = nil) {
        self.state = State(navigationTitle: title)
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
            if let tomorrowDate = state.calendar.date(byAdding: .day, value: 1, to: Date()) {
                state.dueDate = max(dueDate, tomorrowDate)
            }
        case .setTabViewTag(let tag):
            state.tabViewTag = tag
        case .toggleDueDate:
            if state.hasDueDate {
                state.dueDate = nil
            } else {
                state.dueDate = state.calendar.date(byAdding: .day, value: 1, to: Date())
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

    var todoCreation: TodoRequest {
        return TodoRequest(
            title: state.title,
            content: state.content,
            dueDate: state.dueDate,
            tags: state.tags
        )
    }
}
