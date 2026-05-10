//
//  TodoListViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

@Observable
final class TodoListViewModel: Store {
    struct State: Equatable {
        var todos: [TodoListItem] = []
        var searchText: String = ""
        var searchResults: [TodoListItem] = []
        let category: TodoCategory
        var showEditor: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var isSearching: Bool = false
        var showAllSearchResults: Bool = false
        var query: TodoQuery
        var isLoading: Bool = false
        var showToast: Bool = false
        var toastMessage: String = ""
        var hasMore: Bool = false
    }

    enum Action {
        // User
        case refresh
        case setAlert(Bool)
        case setShowEditor(Bool)
        case swipeTodo(TodoListItem)
        case setSortTarget(TodoQuery.SortTarget)
        case setSortOrder(TodoQuery.SortOrder)
        case togglePinnedOnly
        case setCompletionFilter(TodoQuery.CompletionFilter)
        case resetFilters
        case setIsSearching(Bool)
        case setShowAllSearchResults(Bool)
        case tapToggleCompleted(TodoListItem)
        case tapTogglePinned(TodoListItem)
        case undoDelete

        // View
        case onAppear
        case loadNextPage
        case setSearchText(String)
        case setToast(isPresented: Bool)
        case upsertTodo(Todo)

        // Run
        case applySearchQuery(String)
        case fetchSearchResults([TodoListItem])
        case didToggleCompleted(TodoListItem)
        case didTogglePinned(TodoListItem)
        case setTodoHidden(String, Bool)
        case setLoading(Bool)
        case appendTodos([TodoListItem], nextCursor: TodoCursor?)
        case resetPagination
        case setHasMore(Bool)
    }

    enum SideEffect {
        case cancelSearch
        case debounceSearch(String)
        case fetch
        case loadNextPage
        case search(String)
        case upsert(Todo)
        case delete(TodoListItem)
        case undoDelete(String)
        case toggleCompleted(TodoListItem)
        case togglePinned(TodoListItem)
    }

    private enum SearchTaskKind: Hashable {
        case debounce
        case request
    }

    private(set) var state: State
    private let fetchTodosUseCase: FetchTodosUseCase
    private let fetchTodoByIdUseCase: FetchTodoByIdUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    private let undoDeleteTodoUseCase: UndoDeleteTodoUseCase
    private let loadingState = LoadingState()
    private var undoTodoId: String?
    private var nextCursor: TodoCursor?
    private var searchTasks: [SearchTaskKind: Task<Void, Never>] = [:]
    private let searchDebounceDelay: Double = 0.4

    init(
        fetchTodosUseCase: FetchTodosUseCase,
        fetchTodoByIdUseCase: FetchTodoByIdUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        deleteTodoUseCase: DeleteTodoUseCase,
        undoDeleteTodoUseCase: UndoDeleteTodoUseCase,
        category: TodoCategory
    ) {
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchTodoByIdUseCase = fetchTodoByIdUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.undoDeleteTodoUseCase = undoDeleteTodoUseCase
        self.state = State(
            category: category,
            query: TodoQuery(category: category)
        )
    }

    let searchResultsLimit = 5

    var category: TodoCategory {
        state.category
    }

    var appliedFilterCount: Int {
        var count = 0
        if state.query.sortTarget != .createdAt { count += 1 }
        if state.query.sortOrder != .latest { count += 1 }
        if state.query.isPinned != nil { count += 1 }
        if state.query.completionFilter != .all { count += 1 }
        return count
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .refresh, .setAlert, .setShowEditor, .swipeTodo, .setSortTarget, .setSortOrder,
                .togglePinnedOnly, .setCompletionFilter, .resetFilters, .setIsSearching,
                .setShowAllSearchResults, .tapToggleCompleted, .tapTogglePinned, .undoDelete:
            effects = reduceByUser(action, state: &state)

        case .onAppear, .loadNextPage, .setSearchText, .setToast, .upsertTodo:
            effects = reduceByView(action, state: &state)

        case .applySearchQuery, .fetchSearchResults, .didToggleCompleted, .didTogglePinned,
                .setTodoHidden, .setLoading, .appendTodos, .resetPagination, .setHasMore:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
        return effects
    }

    // swiftlint:disable function_body_length
    func run(_ effect: SideEffect) {
        switch effect {
        case .cancelSearch:
            cancelSearch()
        case .debounceSearch(let keyword):
            beginLoading(.immediate)
            scheduleDebouncedSearch(keyword)
        case .fetch:
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    let page = try await fetchTodosUseCase.execute(state.query, cursor: nil)
                    send(.resetPagination)
                    send(.appendTodos(page.items.compactMap { TodoListItem(from: $0) }, nextCursor: page.nextCursor))
                    let hasMore = page.items.count == state.query.pageSize && page.nextCursor != nil
                    send(.setHasMore(hasMore))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .loadNextPage:
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    let page = try await fetchTodosUseCase.execute(state.query, cursor: nextCursor)
                    send(.appendTodos(page.items.compactMap { TodoListItem(from: $0) }, nextCursor: page.nextCursor))
                    let hasMore = page.items.count == state.query.pageSize && page.nextCursor != nil
                    send(.setHasMore(hasMore))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .search(let keyword):
            searchTasks[.request]?.cancel()
            let requestTask = Task { [weak self] in
                guard let self else { return }
                do {
                    defer {
                        self.searchTasks[.request] = nil
                        if !Task.isCancelled {
                            self.endLoading(.immediate)
                        }
                    }
                    let query = TodoQuery(category: state.category, keyword: keyword)
                    let page = try await fetchTodosUseCase.execute(query, cursor: nil)
                    if Task.isCancelled { return }
                    send(.fetchSearchResults(page.items.compactMap { TodoListItem(from: $0) }))
                } catch {
                    if error is CancellationError { return }
                    send(.setAlert(true))
                }
            }
            searchTasks[.request] = requestTask
        case .upsert(let item):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    try await upsertTodoUseCase.execute(item)
                    send(.refresh)
                } catch {
                    send(.setAlert(true))
                }
            }
        case .toggleCompleted(let item):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    var todo = try await fetchTodoByIdUseCase.execute(item.id)
                    let now = Date()
                    todo.isCompleted.toggle()
                    todo.completedAt = todo.isCompleted ? now : nil
                    todo.updatedAt = now
                    try await upsertTodoUseCase.execute(todo)
                    guard let todoListItem = TodoListItem(from: todo) else {
                        send(.setAlert(true))
                        return
                    }
                    send(.didToggleCompleted(todoListItem))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .togglePinned(let item):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    var todo = try await fetchTodoByIdUseCase.execute(item.id)
                    todo.isPinned.toggle()
                    todo.updatedAt = Date()
                    try await upsertTodoUseCase.execute(todo)
                    guard let todoListItem = TodoListItem(from: todo) else {
                        send(.setAlert(true))
                        return
                    }
                    send(.didTogglePinned(todoListItem))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .delete(let item):
            Task {
                do {
                    try await deleteTodoUseCase.execute(item.id)
                } catch {
                    send(.setTodoHidden(item.id, false))
                    send(.setAlert(true))
                }
            }
        case .undoDelete(let todoId):
            Task {
                do {
                    try await undoDeleteTodoUseCase.execute(todoId)
                } catch {
                    send(.setTodoHidden(todoId, true))
                    send(.setAlert(true))
                }
            }
        }
    }
    // swiftlint:enable function_body_length
}

// MARK: - Reduce Methods
private extension TodoListViewModel {
    func reduceByUser(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .refresh:
            return [.fetch]
        case .setAlert(let value):
            setAlert(&state, isPresented: value)
        case .setShowEditor(let value):
            state.showEditor = value
        case .swipeTodo(let todo):
            if state.todos.contains(where: { $0.id == todo.id }) {
                self.undoTodoId = todo.id
                setTodoHidden(&state, todoId: todo.id, isHidden: true)
                setToast(&state, isPresented: true)
                return [.delete(todo)]
            }
        case .setSortTarget(let target):
            state.query.sortTarget = target
            self.nextCursor = nil
            return [.fetch]
        case .setSortOrder(let order):
            state.query.sortOrder = order
            self.nextCursor = nil
            return [.fetch]
        case .togglePinnedOnly:
            state.query.isPinned = state.query.isPinned == true ? nil : true
            self.nextCursor = nil
            return [.fetch]
        case .setCompletionFilter(let filter):
            state.query.completionFilter = filter
            self.nextCursor = nil
            return [.fetch]
        case .resetFilters:
            state.query = TodoQuery(category: state.category)
            self.nextCursor = nil
            return [.fetch]
        case .setIsSearching(let value):
            state.isSearching = value
            if !value {
                state.searchText = ""
                state.searchResults = []
                state.showAllSearchResults = false
                return [.cancelSearch]
            }
        case .setShowAllSearchResults(let value):
            state.showAllSearchResults = value
        case .tapToggleCompleted(let todo):
            return [.toggleCompleted(todo)]
        case .tapTogglePinned(let todo):
            return [.togglePinned(todo)]
        case .undoDelete:
            guard let undoTodoId else { return [] }
            setTodoHidden(&state, todoId: undoTodoId, isHidden: false)
            self.undoTodoId = nil
            return [.undoDelete(undoTodoId)]
        default:
            break
        }
        return []
    }

    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .onAppear:
            return [.fetch]
        case .loadNextPage:
            guard state.hasMore, !state.isLoading else { return [] }
            return [.loadNextPage]
        case .setSearchText(let text):
            guard state.searchText != text else { return [] }
            state.searchText = text
            state.showAllSearchResults = false
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                state.searchResults = []
                return [.cancelSearch]
            } else {
                return [.cancelSearch, .debounceSearch(trimmed)]
            }
        case .setToast(let isPresented):
            setToast(&state, isPresented: isPresented)
            if !isPresented {
                state.todos.removeAll { $0.isHidden }
                state.searchResults.removeAll { $0.isHidden }
                self.undoTodoId = nil
            }
        case .upsertTodo(let todo):
            return [.upsert(todo)]
        default:
            break
        }
        return []
    }

    func reduceByRun(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .applySearchQuery(let query):
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                state.searchResults = []
                return [.cancelSearch]
            } else {
                return [.search(trimmed)]
            }
        case .fetchSearchResults(let items):
            state.searchResults = items
        case .didToggleCompleted(let todo):
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.todos[index] = todo
            }
        case .didTogglePinned(let todo):
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.todos[index] = todo
            }
        case .setTodoHidden(let todoId, let isHidden):
            setTodoHidden(&state, todoId: todoId, isHidden: isHidden)
        case .setLoading(let value):
            state.isLoading = value
        case .appendTodos(let todos, let nextCursor):
            state.todos.append(contentsOf: todos)
            self.nextCursor = nextCursor
        case .resetPagination:
            state.todos = []
            self.nextCursor = nil
            state.hasMore = false
        case .setHasMore(let value):
            state.hasMore = value
        default:
            break
        }
        return []
    }
}

// MARK: - Helper Methods
private extension TodoListViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }

    func setToast(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.toastMessage = String(localized: "common_undo")
        state.showToast = isPresented
    }

    func setTodoHidden(
        _ state: inout State,
        todoId: String,
        isHidden: Bool
    ) {
        if let todoIndex = state.todos.firstIndex(where: { $0.id == todoId }) {
            state.todos[todoIndex].isHidden = isHidden
        }

        if let searchResultIndex = state.searchResults.firstIndex(where: { $0.id == todoId }) {
            state.searchResults[searchResultIndex].isHidden = isHidden
        }
    }

    func scheduleDebouncedSearch(_ query: String) {
        searchTasks[.debounce]?.cancel()
        let debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(searchDebounceDelay))
            if Task.isCancelled { return }
            await MainActor.run {
                self.searchTasks[.debounce] = nil
                self.send(.applySearchQuery(query))
            }
        }
        searchTasks[.debounce] = debounceTask
    }

    func cancelSearch() {
        searchTasks.values.forEach { $0.cancel() }
        searchTasks = [:]
        endLoading(.immediate)
    }

    private func beginLoading(_ mode: LoadingState.Mode) {
        loadingState.begin(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    private func endLoading(_ mode: LoadingState.Mode) {
        loadingState.end(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }
}

extension TodoQuery.SortTarget {
    var title: String {
        switch self {
        case .createdAt:
            return String(localized: "todo_sort_created")
        case .completedAt:
            return String(localized: "profile_activity_completed")
        case .deletedAt:
            return String(localized: "profile_activity_deleted")
        case .updatedAt:
            return String(localized: "todo_sort_updated")
        case .dueDate:
            return String(localized: "todo_sort_due_date")
        }
    }
}

extension TodoQuery.SortOrder {
    var title: String {
        switch self {
        case .latest:
            return String(localized: "todo_sort_latest")
        case .oldest:
            return String(localized: "todo_sort_oldest")
        }
    }
}

extension TodoQuery.CompletionFilter {
    var title: String {
        switch self {
        case .all:
            return String(localized: "todo_completion_all")
        case .incomplete:
            return String(localized: "todo_completion_incomplete")
        case .completed:
            return String(localized: "todo_completion_completed")
        }
    }
}
