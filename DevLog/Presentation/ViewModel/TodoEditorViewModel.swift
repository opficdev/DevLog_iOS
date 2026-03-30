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
        let category: TodoCategory

        init(todo: Todo) {
            self.isCompleted = todo.isCompleted
            self.completedAt = todo.completedAt
            self.isPinned = todo.isPinned
            self.title = todo.title
            self.content = todo.content
            self.dueDate = todo.dueDate
            self.tags = todo.tags
            self.category = todo.category
        }

        init(state: State) {
            self.isCompleted = state.isCompleted
            self.completedAt = state.completedAt
            self.isPinned = state.isPinned
            self.title = state.title
            self.content = state.content
            self.dueDate = state.dueDate
            self.tags = Array(state.tags)
            self.category = state.category.category
        }
    }

    struct State: Equatable {
        var isCompleted: Bool = false
        var completedAt: Date?
        var isPinned: Bool = false
        var selectedTodoId: TodoIdItem?
        var title: String = ""
        var content: String = ""
        var referenceItems: [Int: TodoReferenceItem] = [:]
        var dueDate: Date?
        var showInfo: Bool = false
        var tags: OrderedSet<String> = []
        var tagText: String = ""
        var focusOnEditor: Bool = false
        var tabViewTag: Tag = .editor
        var categories: [TodoCategoryPreferenceItem] = []
        var category = TodoCategoryPreferenceItem(from: .system(.etc))
        var isValidToSave: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Tag {
        case editor, preview
    }

    enum Action {
        case onAppear
        case addTag(String)
        case removeTag(String)
        case setContent(String)
        case setCompleted(Bool)
        case setDueDate(Date?)
        case setCategory(TodoCategoryPreferenceItem)
        case setPinned(Bool)
        case setShowInfo(Bool)
        case setSelectedTodoId(TodoIdItem?)
        case setTabViewTag(Tag)
        case setTagText(String)
        case setTitle(String)
        case setCategories([TodoCategoryPreferenceItem])
        case setReferenceItems([Int: TodoReferenceItem])
    }

    enum SideEffect {
        case fetchCategories
        case resolveMarkdown(String)
    }

    private(set) var state = State()
    private let calendar = Calendar.current
    private let fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase
    private let fetchReferenceItemsUseCase: FetchReferenceItemsUseCase
    private let id: String
    private let isCompleted: Bool
    private let isChecked: Bool
    private let number: Int?
    private let createdAt: Date?
    private let originalDraft: Draft?

    var navigationTitle: String {
        if originalDraft == nil {
            return "새 \(state.category.localizedName) 추가"
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
    init(
        category: TodoCategory,
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase,
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase
    ) {
        self.fetchPreferencesUseCase = fetchPreferencesUseCase
        self.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
        self.id = UUID().uuidString
        self.isCompleted = false
        self.isChecked = false
        self.number = nil
        self.createdAt = nil
        self.originalDraft = nil
        state.category = TodoCategoryPreferenceItem(from: category)
        state.categories = [TodoCategoryPreferenceItem(from: category)]
    }

    // 기존 Todo 편집용 생성자
    init(
        todo: Todo,
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase,
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase
    ) {
        self.fetchPreferencesUseCase = fetchPreferencesUseCase
        self.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
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
        state.category = TodoCategoryPreferenceItem(from: todo.category)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .onAppear:
            effects = [.fetchCategories]
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
            if state.tabViewTag == .preview {
                effects = [.resolveMarkdown(state.content)]
            }
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
        case .setCategory(let todoCategoryItem):
            state.category = todoCategoryItem
        case .setPinned(let isPinned):
            state.isPinned = isPinned
        case .setShowInfo(let isPresented):
            state.showInfo = isPresented
        case .setSelectedTodoId(let todoId):
            state.selectedTodoId = todoId
        case .setTabViewTag(let tag):
            state.tabViewTag = tag
            if tag == .preview {
                effects = [.resolveMarkdown(state.content)]
            }
        case .setCategories(let categories):
            state.categories = categories
        case .setReferenceItems(let items):
            state.referenceItems = items
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchCategories:
            Task {
                do {
                    let preferences = try await fetchPreferencesUseCase.execute()
                    send(.setCategories(preferences.map(TodoCategoryPreferenceItem.init(from:))))
                } catch { }
            }
        case .resolveMarkdown(let content):
            Task {
                let numbers = content.todoReferenceNumbers
                var referenceItems = [Int: TodoReferenceItem]()

                if !numbers.isEmpty {
                    do {
                        referenceItems = try await fetchReferenceItemsUseCase.execute(numbers)
                            .mapValues(TodoReferenceItem.init(from:))
                    } catch {
                        referenceItems = [:]
                    }
                }

                send(.setReferenceItems(referenceItems))
            }
        }
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
            category: state.category.category
        )
    }
}
