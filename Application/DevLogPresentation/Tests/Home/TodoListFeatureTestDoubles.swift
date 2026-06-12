//
//  TodoListFeatureTestDoubles.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/12/26.
//

import Foundation
import DevLogCore
import DevLogDomain
@testable import DevLogPresentation

@MainActor
final class TodoListStoreTestAdapter {
    private let viewModel: TodoListViewModel

    var todos: [TodoListItem] { viewModel.state.todos }
    var searchText: String { viewModel.state.searchText }
    var searchResults: [TodoListItem] { viewModel.state.searchResults }
    var isSearching: Bool { viewModel.state.isSearching }
    var showAllSearchResults: Bool { viewModel.state.showAllSearchResults }
    var query: TodoQuery { viewModel.state.query }
    var isLoading: Bool { viewModel.state.isLoading }
    var hasMore: Bool { viewModel.state.hasMore }
    var showAlert: Bool { viewModel.state.showAlert }
    var alertTitle: String { viewModel.state.alertTitle }
    var alertMessage: String { viewModel.state.alertMessage }
    var appliedFilterCount: Int { viewModel.appliedFilterCount }

    init(
        fetchUseCase: FetchTodosUseCase = TodoListFetchTodosUseCaseSpy(),
        fetchTodoByIdUseCase: FetchTodoByIdUseCase = TodoListFetchTodoByIdUseCaseSpy(),
        upsertUseCase: UpsertTodoUseCase = TodoListUpsertTodoUseCaseSpy(),
        deleteUseCase: DeleteTodoUseCase = TodoListDeleteTodoUseCaseSpy(),
        undoDeleteUseCase: UndoDeleteTodoUseCase = TodoListUndoDeleteTodoUseCaseSpy(),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase = TodoListTrackAnalyticsEventUseCaseSpy(),
        category: TodoCategory = .system(.feature)
    ) {
        viewModel = TodoListViewModel(
            fetchTodosUseCase: fetchUseCase,
            fetchTodoByIdUseCase: fetchTodoByIdUseCase,
            upsertTodoUseCase: upsertUseCase,
            deleteTodoUseCase: deleteUseCase,
            undoDeleteTodoUseCase: undoDeleteUseCase,
            trackAnalyticsEventUseCase: trackAnalyticsEventUseCase,
            category: category
        )
    }

    func onAppear() async {
        viewModel.send(.onAppear)
    }

    func loadNextPage() async {
        viewModel.send(.loadNextPage)
    }

    func setSortTarget(_ target: TodoQuery.SortTarget) async {
        viewModel.send(.setSortTarget(target))
    }

    func setSortOrder(_ order: TodoQuery.SortOrder) async {
        viewModel.send(.setSortOrder(order))
    }

    func togglePinnedOnly() async {
        viewModel.send(.togglePinnedOnly)
    }

    func setCompletionFilter(_ filter: TodoQuery.CompletionFilter) async {
        viewModel.send(.setCompletionFilter(filter))
    }

    func resetFilters() async {
        viewModel.send(.resetFilters)
    }

    func setSearchText(_ text: String) async {
        viewModel.send(.setSearchText(text))
    }

    func setSearchResults(_ results: [TodoListItem]) async {
        viewModel.send(.fetchSearchResults(results))
    }

    func setIsSearching(_ value: Bool) async {
        viewModel.send(.setIsSearching(value))
    }

    func setShowAllSearchResults(_ value: Bool) async {
        viewModel.send(.setShowAllSearchResults(value))
    }

    func appendTodos(_ todos: [TodoListItem]) async {
        viewModel.send(.appendTodos(todos, nextCursor: nil))
    }

    func swipeTodo(_ todo: TodoListItem) async {
        viewModel.send(.swipeTodo(todo))
    }

    func undoDelete() async {
        viewModel.send(.undoDelete)
    }

    func finishDeleteToast(_ todoId: String) async {
        viewModel.send(.finishDeleteToast(todoId))
    }

    func tapToggleCompleted(_ todo: TodoListItem) async {
        viewModel.send(.tapToggleCompleted(todo))
    }

    func tapTogglePinned(_ todo: TodoListItem) async {
        viewModel.send(.tapTogglePinned(todo))
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
