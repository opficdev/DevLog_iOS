//
//  TodoListFeatureTestDoubles.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/12/26.
//

import Foundation
import ComposableArchitecture
import DevLogCore
import DevLogDomain
@testable import DevLogPresentation

@MainActor
final class TodoListStoreTestAdapter {
    private let store: TestStoreOf<TodoListFeature>

    var todos: [TodoListItem] { store.state.todos }
    var searchText: String { store.state.searchText }
    var searchResults: [TodoListItem] { store.state.searchResults }
    var isSearching: Bool { store.state.isSearching }
    var showAllSearchResults: Bool { store.state.showAllSearchResults }
    var query: TodoQuery { store.state.query }
    var isLoading: Bool { store.state.isLoading }
    var hasMore: Bool { store.state.hasMore }
    var alert: AlertState<Never>? { store.state.alert }
    var fullScreenCover: TodoListFeature.FullScreenCoverState? { store.state.fullScreenCover }
    var showAlert: Bool { store.state.alert != nil }
    var appliedFilterCount: Int { store.state.appliedFilterCount }

    init(
        fetchUseCase: FetchTodosUseCase = TodoListFetchTodosUseCaseSpy(),
        fetchTodoByIdUseCase: FetchTodoByIdUseCase = TodoListFetchTodoByIdUseCaseSpy(),
        upsertUseCase: UpsertTodoUseCase = TodoListUpsertTodoUseCaseSpy(),
        deleteUseCase: DeleteTodoUseCase = TodoListDeleteTodoUseCaseSpy(),
        undoDeleteUseCase: UndoDeleteTodoUseCase = TodoListUndoDeleteTodoUseCaseSpy(),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase = TodoListTrackAnalyticsEventUseCaseSpy(),
        category: TodoCategory = .system(.feature),
        configureDependencies: ((inout DependencyValues) -> Void)? = nil
    ) {
        store = TestStore(initialState: TodoListFeature.State(category: category)) {
            TodoListFeature()
        } withDependencies: {
            $0.todoListFetchTodosUseCase = fetchUseCase
            $0.fetchTodoByIdUseCase = fetchTodoByIdUseCase
            $0.upsertTodoUseCase = upsertUseCase
            $0.todoListDeleteTodoUseCase = deleteUseCase
            $0.todoListUndoDeleteTodoUseCase = undoDeleteUseCase
            $0.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
            $0.continuousClock = ContinuousClock()
            configureDependencies?(&$0)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func onAppear() async {
        await store.send(.onAppear)
        await drainReceivedActions()
    }

    func loadNextPage() async {
        await store.send(.loadNextPage)
        await drainReceivedActions()
    }

    func setSortTarget(_ target: TodoQuery.SortTarget) async {
        await store.send(.binding(.set(\.query.sortTarget, target)))
        await drainReceivedActions()
    }

    func setSortOrder(_ order: TodoQuery.SortOrder) async {
        await store.send(.binding(.set(\.query.sortOrder, order)))
        await drainReceivedActions()
    }

    func togglePinnedOnly() async {
        await store.send(.binding(.set(\.isPinnedOnly, !store.state.isPinnedOnly)))
        await drainReceivedActions()
    }

    func setCompletionFilter(_ filter: TodoQuery.CompletionFilter) async {
        await store.send(.binding(.set(\.query.completionFilter, filter)))
        await drainReceivedActions()
    }

    func resetFilters() async {
        await store.send(.resetFilters)
        await drainReceivedActions()
    }

    func setSearchText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        await store.send(.binding(.set(\.searchText, text)))
        await drainReceivedActions()

        if !trimmed.isEmpty {
            try? await Task.sleep(for: .milliseconds(450))
            await drainReceivedActions()
        }
    }

    func setSearchResults(_ results: [TodoListItem]) async {
        await store.send(.fetchSearchResults(results))
    }

    func setIsSearching(_ value: Bool) async {
        await store.send(.binding(.set(\.isSearching, value)))
        await drainReceivedActions()
    }

    func setShowAllSearchResults(_ value: Bool) async {
        await store.send(.binding(.set(\.showAllSearchResults, value)))
    }

    func appendTodos(_ todos: [TodoListItem]) async {
        await store.send(.appendTodos(todos, nextCursor: nil))
    }

    func setFullScreenCover(_ cover: TodoListFeature.FullScreenCoverState?) async {
        await store.send(.setFullScreenCover(cover))
    }

    func dismissFullScreenCover() async {
        await store.send(.fullScreenCover(.dismiss))
    }

    func swipeTodo(_ todo: TodoListItem) async {
        await store.send(.swipeTodo(todo))
        await store.send(.presentedDeleteToast)
        await drainReceivedActions()
    }

    func undoDelete() async {
        await store.send(.undoDelete)
        await drainReceivedActions()
    }

    func finishDeleteToast(_ todoId: String) async {
        await store.send(.finishDeleteToast(todoId))
    }

    func tapToggleCompleted(_ todo: TodoListItem) async {
        await store.send(.tapToggleCompleted(todo))
        await drainReceivedActions()
    }

    func tapTogglePinned(_ todo: TodoListItem) async {
        await store.send(.tapTogglePinned(todo))
        await drainReceivedActions()
    }

    private func drainReceivedActions() async {
        for _ in 0..<8 {
            await store.skipReceivedActions(strict: false)
        }
    }
}

func expectedTodoListErrorAlert() -> AlertState<Never> {
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

final class TodoListFetchTodosUseCaseSpy: FetchTodosUseCase {
    var pages: [TodoPage]
    var error: Error?
    private(set) var queries = [TodoQuery]()
    private(set) var cursors = [TodoCursor?]()

    init(pages: [TodoPage] = [TodoPage(items: [], nextCursor: nil)]) {
        self.pages = pages
    }

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)
        cursors.append(cursor)

        if let error {
            throw error
        }

        if pages.count <= queries.count - 1 {
            return pages.last ?? TodoPage(items: [], nextCursor: nil)
        }

        return pages[queries.count - 1]
    }
}

final class TodoListFetchTodoByIdUseCaseSpy: FetchTodoByIdUseCase {
    var todos: [Todo]
    var error: Error?
    private(set) var todoIds = [String]()

    init(todos: [Todo] = []) {
        self.todos = todos
    }

    func execute(_ todoId: String) async throws -> Todo {
        todoIds.append(todoId)

        if let error {
            throw error
        }

        return todos.first { $0.id == todoId } ?? makeTodoListTodo(id: todoId)
    }
}

final class TodoListUpsertTodoUseCaseSpy: UpsertTodoUseCase {
    var error: Error?
    private(set) var todos = [Todo]()
    private(set) var todoDrafts = [TodoDraft]()

    func execute(_ todo: Todo) async throws {
        todos.append(todo)

        if let error {
            throw error
        }
    }

    func execute(_ todoDraft: TodoDraft) async throws {
        todoDrafts.append(todoDraft)

        if let error {
            throw error
        }
    }
}

final class TodoListDeleteTodoUseCaseSpy: DeleteTodoUseCase {
    var error: Error?
    private(set) var todoIds = [String]()

    func execute(_ todoId: String) async throws {
        todoIds.append(todoId)

        if let error {
            throw error
        }
    }
}

final class TodoListUndoDeleteTodoUseCaseSpy: UndoDeleteTodoUseCase {
    var error: Error?
    private(set) var todoIds = [String]()

    func execute(_ todoId: String) async throws {
        todoIds.append(todoId)

        if let error {
            throw error
        }
    }
}

final class TodoListTrackAnalyticsEventUseCaseSpy: TrackAnalyticsEventUseCase {
    private(set) var events = [AnalyticsEvent]()
    var hasTrackedTodoComplete: Bool {
        events.contains {
            guard case .todoComplete = $0 else { return false }
            return true
        }
    }

    func execute(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

enum TodoListTestError: Error {
    case failure
}

func makeTodoListTodo(
    id: String = "todo-1",
    isPinned: Bool = false,
    isCompleted: Bool = false,
    number: Int = 1,
    title: String = "Todo"
) -> Todo {
    Todo(
        id: id,
        isPinned: isPinned,
        isCompleted: isCompleted,
        isChecked: false,
        number: number,
        title: title,
        content: "content",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0),
        completedAt: isCompleted ? Date(timeIntervalSince1970: 0) : nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: .system(.feature)
    )
}

func makeTodoListCursor(documentID: String) -> TodoCursor {
    TodoCursor(
        primarySortDate: Date(timeIntervalSince1970: 0),
        secondarySortDate: Date(timeIntervalSince1970: 0),
        documentID: documentID
    )
}
