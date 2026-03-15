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
        let kind: TodoKind
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
        case confirmDelete
        case onAppear
        case loadNextPage
        case setSearchText(String)
        case setToast(isPresented: Bool)
        case upsertTodo(Todo)

        // Run
        case setSearchQuery(String)
        case fetchSearchResults([TodoListItem])
        case didToggleCompleted(TodoListItem)
        case didTogglePinned(TodoListItem)
        case restoreTodo(TodoListItem, Int)
        case setLoading(Bool)
        case appendTodos([TodoListItem], nextCursor: TodoCursor?)
        case resetPagination
        case setHasMore(Bool)
    }

    enum SideEffect {
        case fetch
        case loadNextPage
        case search(String)
        case upsert(Todo)
        case delete(TodoListItem, Int)
        case undoDelete(String)
        case toggleCompleted(TodoListItem)
        case togglePinned(TodoListItem)
    }

    private(set) var state: State
    private let searchDebounceDelay: Double = 0.4
    private var searchDebounceTask: Task<Void, Never>?
    private let fetchTodosUseCase: FetchTodosUseCase
    private let fetchTodoByIdUseCase: FetchTodoByIdUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    private let undoDeleteTodoUseCase: UndoDeleteTodoUseCase
    private var pendingTask: (TodoListItem, Int)?
    private var nextCursor: TodoCursor?

    init(
        fetchTodosUseCase: FetchTodosUseCase,
        fetchTodoByIdUseCase: FetchTodoByIdUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        deleteTodoUseCase: DeleteTodoUseCase,
        undoDeleteTodoUseCase: UndoDeleteTodoUseCase,
        kind: TodoKind
    ) {
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchTodoByIdUseCase = fetchTodoByIdUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.undoDeleteTodoUseCase = undoDeleteTodoUseCase
        self.state = State(
            kind: kind,
            query: TodoQuery(kind: kind)
        )
    }

    let searchResultsLimit = 5

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

        case .confirmDelete, .onAppear, .loadNextPage, .setSearchText, .setToast, .upsertTodo:
            effects = reduceByView(action, state: &state)

        case .setSearchQuery, .fetchSearchResults, .didToggleCompleted, .didTogglePinned,
                .restoreTodo, .setLoading, .appendTodos, .resetPagination, .setHasMore:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetch:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let page = try await fetchTodosUseCase.execute(state.query, cursor: nil)
                    send(.resetPagination)
                    send(.appendTodos(page.items.map { TodoListItem(from: $0) }, nextCursor: page.nextCursor))
                    let hasMore = page.items.count == state.query.pageSize && page.nextCursor != nil
                    send(.setHasMore(hasMore))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .loadNextPage:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let page = try await fetchTodosUseCase.execute(state.query, cursor: nextCursor)
                    send(.appendTodos(page.items.map { TodoListItem(from: $0) }, nextCursor: page.nextCursor))
                    let hasMore = page.items.count == state.query.pageSize && page.nextCursor != nil
                    send(.setHasMore(hasMore))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .search(let keyword):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let query = TodoQuery(kind: state.kind, keyword: keyword)
                    let page = try await fetchTodosUseCase.execute(query, cursor: nil)
                    send(.fetchSearchResults(page.items.map { TodoListItem(from: $0) }))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .upsert(let item):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    try await upsertTodoUseCase.execute(item)
                    send(.refresh)
                } catch {
                    send(.setAlert(true))
                }
            }
        case .toggleCompleted(let item):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    var todo = try await fetchTodoByIdUseCase.execute(item.id)
                    let now = Date()
                    todo.isCompleted.toggle()
                    todo.completedAt = todo.isCompleted ? now : nil
                    todo.updatedAt = now
                    try await upsertTodoUseCase.execute(todo)
                    send(.didToggleCompleted(TodoListItem(from: todo)))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .togglePinned(let item):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    var todo = try await fetchTodoByIdUseCase.execute(item.id)
                    todo.isPinned.toggle()
                    todo.updatedAt = Date()
                    try await upsertTodoUseCase.execute(todo)
                    send(.didTogglePinned(TodoListItem(from: todo)))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .delete(let item, let index):
            Task {
                do {
                    try await deleteTodoUseCase.execute(item.id)
                } catch {
                    send(.restoreTodo(item, index))
                    send(.setAlert(true))
                }
            }
        case .undoDelete(let todoId):
            Task {
                do {
                    try await undoDeleteTodoUseCase.execute(todoId)
                    send(.refresh)
                } catch {
                    send(.setAlert(true)); send(.refresh)
                }
            }
        }
    }
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
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                pendingTask = (todo, index)
                state.todos.remove(at: index)
                setToast(&state, isPresented: true)
                return [.delete(todo, index)]
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
            state.query = TodoQuery(kind: state.kind)
            self.nextCursor = nil
            return [.fetch]
        case .setIsSearching(let value):
            state.isSearching = value
            if !value {
                cancelDebounce()
                state.searchText = ""
                state.searchResults = []
                state.showAllSearchResults = false
            }
        case .setShowAllSearchResults(let value):
            state.showAllSearchResults = value
        case .tapToggleCompleted(let todo):
            return [.toggleCompleted(todo)]
        case .tapTogglePinned(let todo):
            return [.togglePinned(todo)]
        case .undoDelete:
            guard let (todo, _) = pendingTask else { return [] }
            pendingTask = nil
            return [.undoDelete(todo.id)]
        default:
            break
        }
        return []
    }

    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .confirmDelete:
            pendingTask = nil
        case .onAppear:
            return [.fetch]
        case .loadNextPage:
            guard state.hasMore, !state.isLoading, pendingTask == nil else { return [] }
            return [.loadNextPage]
        case .setSearchText(let text):
            guard state.searchText != text else { return [] }
            state.searchText = text
            state.showAllSearchResults = false
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                cancelDebounce()
                state.searchResults = []
                state.isLoading = false
            } else {
                state.isLoading = true
                scheduleDebouncedQuery(text)
            }
        case .setToast(let isPresented):
            setToast(&state, isPresented: isPresented)
        case .upsertTodo(let todo):
            return [.upsert(todo)]
        default:
            break
        }
        return []
    }

    func reduceByRun(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .setSearchQuery(let query):
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                state.searchResults = []
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
        case .restoreTodo(let todo, let index):
            if state.todos.contains(where: { $0.id == todo.id }) { break }

            if index <= state.todos.count {
                state.todos.insert(todo, at: index)
            } else {
                state.todos.append(todo)
            }

            if let (pendingItem, _) = pendingTask, pendingItem.id == todo.id {
                pendingTask = nil
            }
        case .setLoading(let value):
            state.isLoading = value
        case .appendTodos(let todos, let nextCursor):
            let filteredTodos: [TodoListItem]
            if let (pendingItem, _) = pendingTask {
                filteredTodos = todos.filter { $0.id != pendingItem.id }
            } else {
                filteredTodos = todos
            }
            state.todos.append(contentsOf: filteredTodos)
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
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }

    func setToast(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.toastMessage = "실행 취소"
        state.showToast = isPresented
    }

    func scheduleDebouncedQuery(_ query: String) {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(searchDebounceDelay))
            if Task.isCancelled { return }
            await MainActor.run {
                self.send(.setSearchQuery(query))
            }
        }
    }

    func cancelDebounce() {
        searchDebounceTask?.cancel()
        searchDebounceTask = nil
    }
}

extension TodoQuery.SortTarget {
    var title: String {
        switch self {
        case .createdAt:
            return "생성"
        case .updatedAt:
            return "수정"
        case .dueDate:
            return "마감"
        }
    }
}

extension TodoQuery.SortOrder {
    var title: String {
        switch self {
        case .latest:
            return "최신순"
        case .oldest:
            return "예전순"
        }
    }
}

extension TodoQuery.CompletionFilter {
    var title: String {
        switch self {
        case .all:
            return "완료 + 미완료"
        case .incomplete:
            return "미완료"
        case .completed:
            return "완료"
        }
    }
}
