//
//  TodoEditorFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/12/26.
//

import ComposableArchitecture
import DevLogDomain
import Foundation
import OrderedCollections

@Reducer
struct TodoEditorFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        @Presents var sheet: SheetState?
        var isCompleted: Bool = false
        var completedAt: Date?
        var isPinned: Bool = false
        var title: String = ""
        var content: String = ""
        var referenceItems: [Int: TodoReferenceItem] = [:]
        var dueDate: Date?
        var loading = LoadingFeature.State()
        var tags: OrderedSet<String> = []
        var tagText: String = ""
        var tabViewTag: EditorTab = .editor
        var categories: [TodoCategoryItem] = []
        var category = TodoCategoryItem(from: .system(.etc))
        var saveResult: SaveResult?
        let id: String
        let isChecked: Bool
        let number: Int?
        let createdAt: Date?
        let deletedAt: Date?
        let originalDraft: TodoDraft?

        var isValidToSave: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        var isLoading: Bool {
            loading.isLoading
        }
        var navigationTitle: String {
            if originalDraft == nil {
                return String.localizedStringWithFormat(
                    String(localized: "todo_editor_new_format"),
                    category.localizedName
                )
            }

            return String(localized: "todo_edit")
        }
        var hasChanges: Bool {
            guard let originalDraft else { return true }
            return originalDraft != makeTodoDraft(now: Date())
        }
        var isReadyToSubmit: Bool {
            isValidToSave && hasChanges
        }

        init(category: TodoCategory, id: String = UUID().uuidString) {
            self.id = id
            self.isChecked = false
            self.number = nil
            self.createdAt = nil
            self.deletedAt = nil
            self.originalDraft = nil
            self.category = TodoCategoryItem(from: category)
            self.categories = [TodoCategoryItem(from: category)]
        }

        init(todo: Todo) {
            self.id = todo.id
            self.isChecked = todo.isChecked
            self.number = todo.number
            self.createdAt = todo.createdAt
            self.deletedAt = todo.deletedAt
            self.originalDraft = TodoDraft(todo: todo)
            self.isCompleted = todo.isCompleted
            self.completedAt = todo.completedAt
            self.isPinned = todo.isPinned
            self.title = todo.title
            self.content = todo.content
            self.dueDate = todo.dueDate
            self.tags = OrderedSet(todo.tags)
            self.category = TodoCategoryItem(from: todo.category)
        }
    }

    @ObservableState
    @CasePathable
    enum SheetState: Equatable {
        case info
        case todo(TodoIdItem)
    }

    enum EditorTab: Equatable {
        case editor
        case preview
    }

    enum SaveResult: Equatable {
        case created
        case updated(Todo)
    }

    enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Never>)
        case sheet(PresentationAction<Sheet>)
        case binding(BindingAction<State>)
        case onAppear
        case addTag(String)
        case removeTag(String)
        case setCompleted(Bool)
        case setSheet(SheetState?)
        case upsertTodo
        case createSucceeded
        case saveFailed
        case updateSucceeded(Todo)
        case loading(LoadingFeature.Action)

        enum Sheet: Equatable {
            case tapCloseButton
        }
    }

    private enum CancelID: Hashable {
        case resolveMarkdown
    }

    @Dependency(\.date.now) var now
    @Dependency(\.fetchTodoCategoryPreferencesUseCase) var fetchPreferencesUseCase
    @Dependency(\.fetchReferenceItemsUseCase) var fetchReferenceItemsUseCase
    @Dependency(\.upsertTodoUseCase) var upsertTodoUseCase
    @Dependency(\.trackAnalyticsEventUseCase) var trackAnalyticsEventUseCase

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .sheet(.dismiss):
                state.sheet = nil
            case .sheet(.presented(.tapCloseButton)):
                state.sheet = nil
            case .sheet:
                break
            case .binding(\.content):
                if state.tabViewTag == .preview {
                    return resolveMarkdownEffect(content: state.content)
                }
            case .binding(\.dueDate):
                if let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: now),
                   let dueDate = state.dueDate {
                    state.dueDate = max(dueDate, tomorrowDate)
                } else {
                    state.dueDate = nil
                }
            case .binding(\.tabViewTag):
                if state.tabViewTag == .preview {
                    return resolveMarkdownEffect(content: state.content)
                }
            case .binding:
                break
            case .onAppear:
                return fetchCategoriesEffect()
            case .addTag(let tag):
                if !tag.isEmpty {
                    state.tags.append(tag)
                }
            case .removeTag(let tagText):
                state.tags.removeAll { $0 == tagText }
            case .setCompleted(let isCompleted):
                if state.isCompleted != isCompleted {
                    state.completedAt = isCompleted ? now : nil
                }
                state.isCompleted = isCompleted
            case .setSheet(let sheet):
                state.sheet = sheet
            case .upsertTodo:
                state.saveResult = nil
                if state.originalDraft == nil {
                    return createTodoEffect(state.makeTodoDraft(now: now))
                } else if let todo = state.makeTodo(now: now) {
                    return updateTodoEffect(todo)
                }
            case .createSucceeded:
                state.saveResult = .created
            case .saveFailed:
                state.alert = Self.alertState()
            case .updateSucceeded(let todo):
                state.saveResult = .updated(todo)
            case .loading:
                break
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$sheet, action: \.sheet) {
            TodoEditorSheetFeature()
        }
    }
}

private struct TodoEditorSheetFeature: Reducer {
    typealias State = TodoEditorFeature.SheetState
    typealias Action = TodoEditorFeature.Action.Sheet

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

extension DependencyValues {
    var fetchTodoCategoryPreferencesUseCase: FetchTodoCategoryPreferencesUseCase {
        get { self[FetchTodoCategoryPreferencesUseCaseKey.self] }
        set { self[FetchTodoCategoryPreferencesUseCaseKey.self] = newValue }
    }

    var upsertTodoUseCase: UpsertTodoUseCase {
        get { self[UpsertTodoUseCaseKey.self] }
        set { self[UpsertTodoUseCaseKey.self] = newValue }
    }

    var trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase {
        get { self[TrackAnalyticsEventUseCaseKey.self] }
        set { self[TrackAnalyticsEventUseCaseKey.self] = newValue }
    }
}

private enum FetchTodoCategoryPreferencesUseCaseKey: DependencyKey {
    static var liveValue: FetchTodoCategoryPreferencesUseCase {
        preconditionFailure("FetchTodoCategoryPreferencesUseCase must be provided.")
    }

    static var testValue: FetchTodoCategoryPreferencesUseCase {
        liveValue
    }
}

private enum UpsertTodoUseCaseKey: DependencyKey {
    static var liveValue: UpsertTodoUseCase {
        preconditionFailure("UpsertTodoUseCase must be provided.")
    }

    static var testValue: UpsertTodoUseCase {
        liveValue
    }
}

private enum TrackAnalyticsEventUseCaseKey: DependencyKey {
    static var liveValue: TrackAnalyticsEventUseCase {
        preconditionFailure("TrackAnalyticsEventUseCase must be provided.")
    }

    static var testValue: TrackAnalyticsEventUseCase {
        NoOpTrackAnalyticsEventUseCase()
    }
}

private struct NoOpTrackAnalyticsEventUseCase: TrackAnalyticsEventUseCase {
    func execute(_ event: AnalyticsEvent) { }
}

private extension TodoEditorFeature {
    func fetchCategoriesEffect() -> Effect<Action> {
        .run { [fetchPreferencesUseCase] send in
            do {
                let preferences = try await fetchPreferencesUseCase.execute()
                await send(.binding(.set(\.categories, preferences.map(TodoCategoryItem.init(from:)))))
            } catch { }
        }
    }

    func resolveMarkdownEffect(content: String) -> Effect<Action> {
        .run { [fetchReferenceItemsUseCase] send in
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

            await send(.binding(.set(\.referenceItems, referenceItems)))
        }
        .cancellable(id: CancelID.resolveMarkdown, cancelInFlight: true)
    }

    func createTodoEffect(_ draft: TodoDraft) -> Effect<Action> {
        .run { [trackAnalyticsEventUseCase, upsertTodoUseCase] send in
            await send(.loading(.begin(target: .default, mode: .immediate)))
            do {
                try await upsertTodoUseCase.execute(draft)
                trackAnalyticsEventUseCase.execute(.todoCreate)
                await send(.createSucceeded)
            } catch {
                await send(.saveFailed)
            }
            await send(.loading(.end(target: .default, mode: .immediate)))
        }
    }

    func updateTodoEffect(_ todo: Todo) -> Effect<Action> {
        .run { [upsertTodoUseCase] send in
            await send(.loading(.begin(target: .default, mode: .immediate)))
            do {
                try await upsertTodoUseCase.execute(todo)
                await send(.updateSucceeded(todo))
            } catch {
                await send(.saveFailed)
            }
            await send(.loading(.end(target: .default, mode: .immediate)))
        }
    }

    static func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close"))
            }
        } message: {
            TextState(String(localized: "common_error_message"))
        }
    }
}

private extension TodoEditorFeature.State {
    func makeTodoDraft(now: Date) -> TodoDraft {
        TodoDraft(
            id: id,
            isPinned: isPinned,
            isCompleted: isCompleted,
            isChecked: isChecked,
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now,
            completedAt: completedAt,
            dueDate: dueDate,
            tags: Array(tags),
            category: category.category
        )
    }

    func makeTodo(now: Date) -> Todo? {
        guard let number, let createdAt else { return nil }
        return Todo(
            id: id,
            isPinned: isPinned,
            isCompleted: isCompleted,
            isChecked: isChecked,
            number: number,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: now,
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: dueDate,
            tags: Array(tags),
            category: category.category
        )
    }
}
