//
//  TodoEditorViewModel.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 11/24/25.
//

import Foundation
import OrderedCollections
import DevLogDomain

@Observable
final class TodoEditorViewModel: Store {
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
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var isLoading: Bool = false
        var tags: OrderedSet<String> = []
        var tagText: String = ""
        var focusOnEditor: Bool = false
        var tabViewTag: Tag = .editor
        var categories: [TodoCategoryItem] = []
        var category = TodoCategoryItem(from: .system(.etc))
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
        case setCategory(TodoCategoryItem)
        case setAlert(Bool)
        case setLoading(Bool)
        case setPinned(Bool)
        case setShowInfo(Bool)
        case setSelectedTodoId(TodoIdItem?)
        case setTabViewTag(Tag)
        case setTagText(String)
        case setTitle(String)
        case setCategories([TodoCategoryItem])
        case setReferenceItems([Int: TodoReferenceItem])
        case upsertTodo
    }

    enum SideEffect {
        case fetchCategories
        case resolveMarkdown(String)
        case createTodo(TodoDraft)
        case updateTodo(Todo)
    }

    private(set) var state = State()
    private let calendar = Calendar.current
    private let fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase
    private let fetchReferenceItemsUseCase: FetchReferenceItemsUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase?
    private let onCreateSuccess: (() -> Void)?
    private let onUpdateSuccess: ((Todo) -> Void)?
    private let id: String
    private let isChecked: Bool
    private let number: Int?
    private let createdAt: Date?
    private let deletedAt: Date?
    private let originalDraft: TodoDraft?

    var navigationTitle: String {
        if originalDraft == nil {
            return String.localizedStringWithFormat(
                String(localized: "todo_editor_new_format"),
                state.category.localizedName
            )
        }

        return String(localized: "todo_edit")
    }

    var hasChanges: Bool {
        guard let originalDraft else { return true }
        return originalDraft != makeTodoDraft()
    }

    var isReadyToSubmit: Bool {
        state.isValidToSave && hasChanges
    }

    // 새로운 Todo 생성용 생성자
    init(
        category: TodoCategory,
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase,
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase? = nil,
        onCreateSuccess: (() -> Void)? = nil
    ) {
        self.fetchPreferencesUseCase = fetchPreferencesUseCase
        self.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
        self.onCreateSuccess = onCreateSuccess
        self.onUpdateSuccess = nil
        self.id = UUID().uuidString
        self.isChecked = false
        self.number = nil
        self.createdAt = nil
        self.deletedAt = nil
        self.originalDraft = nil
        state.category = TodoCategoryItem(from: category)
        state.categories = [TodoCategoryItem(from: category)]
    }

    // 기존 Todo 편집용 생성자
    init(
        todo: Todo,
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase,
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase? = nil,
        onUpdateSuccess: ((Todo) -> Void)? = nil
    ) {
        self.fetchPreferencesUseCase = fetchPreferencesUseCase
        self.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
        self.onCreateSuccess = nil
        self.onUpdateSuccess = onUpdateSuccess
        self.id = todo.id
        self.isChecked = todo.isChecked
        self.number = todo.number
        self.createdAt = todo.createdAt
        self.deletedAt = todo.deletedAt
        self.originalDraft = TodoDraft(todo: todo)
        state.isCompleted = todo.isCompleted
        state.completedAt = todo.completedAt
        state.isPinned = todo.isPinned
        state.title = todo.title
        state.content = todo.content
        state.dueDate = todo.dueDate
        state.tags = OrderedSet(todo.tags)
        state.category = TodoCategoryItem(from: todo.category)
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
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .setLoading(let value):
            state.isLoading = value
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
        case .upsertTodo:
            if originalDraft == nil {
                effects = [.createTodo(makeTodoDraft())]
            } else if let todo = makeTodo() {
                effects = [.updateTodo(todo)]
            }
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
                    send(.setCategories(preferences.map(TodoCategoryItem.init(from:))))
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
        case .createTodo(let todoDraft):
            send(.setLoading(true))
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    try await upsertTodoUseCase.execute(todoDraft)
                    trackAnalyticsEventUseCase?.execute(.todoCreate)
                    onCreateSuccess?()
                } catch {
                    send(.setAlert(true))
                }
            }
        case .updateTodo(let todo):
            send(.setLoading(true))
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    try await upsertTodoUseCase.execute(todo)
                    onUpdateSuccess?(todo)
                } catch {
                    send(.setAlert(true))
                }
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

    private func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }

    private func makeTodoDraft() -> TodoDraft {
        let date = Date()
        return TodoDraft(
            id: self.id,
            isPinned: state.isPinned,
            isCompleted: state.isCompleted,
            isChecked: self.isChecked,
            title: state.title,
            content: state.content,
            createdAt: date,
            updatedAt: date,
            completedAt: state.completedAt,
            dueDate: state.dueDate,
            tags: state.tags.map { $0 },
            category: state.category.category
        )
    }

    private func makeTodo() -> Todo? {
        guard let number, let createdAt else { return nil }
        let date = Date()
        return Todo(
            id: self.id,
            isPinned: state.isPinned,
            isCompleted: state.isCompleted,
            isChecked: self.isChecked,
            number: number,
            title: state.title,
            content: state.content,
            createdAt: createdAt,
            updatedAt: date,
            completedAt: state.completedAt,
            deletedAt: self.deletedAt,
            dueDate: state.dueDate,
            tags: state.tags.map { $0 },
            category: state.category.category
        )
    }
}
