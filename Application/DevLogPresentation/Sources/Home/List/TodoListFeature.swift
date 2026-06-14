//
//  TodoListFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/12/26.
//

import ComposableArchitecture
import DevLogCore
import DevLogDomain
import Foundation

@Reducer
struct TodoListFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        @Presents var fullScreenCover: FullScreenCoverState?
        var category: TodoCategory
        var todos: [TodoListItem] = []
        var searchText = ""
        var searchResults: [TodoListItem] = []
        var isSearching = false
        var showAllSearchResults = false
        var query: TodoQuery
        var hasMore = false
        var loading = LoadingFeature.State()
        var undoTodoId: String?
        var nextCursor: TodoCursor?
        var deleteToastTodoId: String?
        let searchResultsLimit = 5

        init(category: TodoCategory) {
            self.category = category
            self.query = TodoQuery(categoryId: category.storageValue)
        }

        var isLoading: Bool {
            loading.isLoading
        }

        var appliedFilterCount: Int {
            var count = 0
            if query.sortTarget != .createdAt { count += 1 }
            if query.sortOrder != .latest { count += 1 }
            if query.isPinned { count += 1 }
            if query.completionFilter != .all { count += 1 }
            return count
        }
    }

    @ObservableState
    struct FullScreenCoverState: Equatable {
        var destination: Destination

        enum Destination: Equatable {
            case editor
        }

        static let editor = Self(destination: .editor)
    }

    enum Action: BindableAction {
        case alert(PresentationAction<Never>)
        case fullScreenCover(PresentationAction<Never>)
        case binding(BindingAction<State>)
        case refresh
        case setFullScreenCover(FullScreenCoverState?)
        case swipeTodo(TodoListItem)
        case resetFilters
        case finishDeleteToast(String)
        case presentedDeleteToast
        case tapToggleCompleted(TodoListItem)
        case tapTogglePinned(TodoListItem)
        case undoDelete
        case onAppear
        case loadNextPage
        case store(StoreAction)
        case loading(LoadingFeature.Action)

        enum StoreAction: Equatable {
            case setAlert(Bool)
            case applySearchQuery(String)
            case fetchSearchResults([TodoListItem])
            case didToggleCompleted(TodoListItem)
            case didTogglePinned(TodoListItem)
            case setTodoHidden(String, Bool)
            case appendTodos([TodoListItem], nextCursor: TodoCursor?)
            case resetPagination
            case setHasMore(Bool)
        }
    }

    enum CancelID: Hashable {
        case debounce
        case fetch
        case request
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.todoListFetchTodosUseCase) var fetchTodosUseCase
    @Dependency(\.fetchTodoByIdUseCase) var fetchTodoByIdUseCase
    @Dependency(\.upsertTodoUseCase) var upsertTodoUseCase
    @Dependency(\.todoListDeleteTodoUseCase) var deleteTodoUseCase
    @Dependency(\.todoListUndoDeleteTodoUseCase) var undoDeleteTodoUseCase
    @Dependency(\.trackAnalyticsEventUseCase) var trackAnalyticsEventUseCase

    private let searchDebounceDelay = Duration.seconds(0.4)

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        BindingReducer()
        Reduce { state, action in
            reduce(action, state: &state)
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension DependencyValues {
    var todoListFetchTodosUseCase: FetchTodosUseCase {
        get { self[TodoListFetchTodosUseCaseKey.self] }
        set { self[TodoListFetchTodosUseCaseKey.self] = newValue }
    }

    var todoListDeleteTodoUseCase: DeleteTodoUseCase {
        get { self[TodoListDeleteTodoUseCaseKey.self] }
        set { self[TodoListDeleteTodoUseCaseKey.self] = newValue }
    }

    var todoListUndoDeleteTodoUseCase: UndoDeleteTodoUseCase {
        get { self[TodoListUndoDeleteTodoUseCaseKey.self] }
        set { self[TodoListUndoDeleteTodoUseCaseKey.self] = newValue }
    }
}

private enum TodoListFetchTodosUseCaseKey: DependencyKey {
    static var liveValue: FetchTodosUseCase {
        preconditionFailure("FetchTodosUseCase must be provided.")
    }

    static var testValue: FetchTodosUseCase {
        liveValue
    }
}

private enum TodoListDeleteTodoUseCaseKey: DependencyKey {
    static var liveValue: DeleteTodoUseCase {
        preconditionFailure("DeleteTodoUseCase must be provided.")
    }

    static var testValue: DeleteTodoUseCase {
        liveValue
    }
}

private enum TodoListUndoDeleteTodoUseCaseKey: DependencyKey {
    static var liveValue: UndoDeleteTodoUseCase {
        preconditionFailure("UndoDeleteTodoUseCase must be provided.")
    }

    static var testValue: UndoDeleteTodoUseCase {
        liveValue
    }
}

private extension TodoListFeature {
    func reduce(_ action: Action, state: inout State) -> Effect<Action> {
        switch action {
        case .alert:
            break
        case .fullScreenCover(.dismiss):
            state.fullScreenCover = nil
        case .fullScreenCover:
            break
        case .binding(\.searchText):
            return setSearchTextEffect(state: &state)
        case .binding(\.isSearching):
            guard !state.isSearching else { break }
            state.searchText = ""
            state.searchResults = []
            state.showAllSearchResults = false
            return cancelSearchEffect()
        case .binding(\.query.sortTarget), .binding(\.query.sortOrder), .binding(\.query.isPinned),
            .binding(\.query.completionFilter):
            state.nextCursor = nil
            return fetchEffect(query: state.query, cursor: nil)
        case .binding:
            break
        case .refresh, .onAppear:
            return fetchEffect(query: state.query, cursor: nil)
        case .store(.setAlert(let value)):
            Self.setAlert(&state, isPresented: value)
        case .setFullScreenCover(let cover):
            state.fullScreenCover = cover
        case .swipeTodo(let todo):
            return swipeTodoEffect(todo, state: &state)
        case .resetFilters:
            state.query = TodoQuery(categoryId: state.category.storageValue)
            state.nextCursor = nil
            return fetchEffect(query: state.query, cursor: nil)
        case .finishDeleteToast(let todoId):
            state.todos.removeAll { $0.id == todoId && $0.isHidden }
            state.searchResults.removeAll { $0.id == todoId && $0.isHidden }
            if state.undoTodoId == todoId {
                state.undoTodoId = nil
            }
        case .presentedDeleteToast:
            state.deleteToastTodoId = nil
        case .tapToggleCompleted(let todo):
            return toggleCompletedEffect(todo)
        case .tapTogglePinned(let todo):
            return togglePinnedEffect(todo)
        case .undoDelete:
            guard let undoTodoId = state.undoTodoId else { return .none }
            Self.setTodoHidden(&state, todoId: undoTodoId, isHidden: false)
            state.undoTodoId = nil
            return undoDeleteEffect(undoTodoId)
        case .loadNextPage:
            guard state.hasMore, !state.isLoading else { return .none }
            return fetchEffect(query: state.query, cursor: state.nextCursor, resetsPagination: false)
        case .store(.applySearchQuery(let query)):
            return applySearchQueryEffect(query, state: &state)
        case .store(.fetchSearchResults(let items)):
            state.searchResults = items
        case .store(.didToggleCompleted(let todo)), .store(.didTogglePinned(let todo)):
            if let index = state.todos.firstIndex(where: { $0.id == todo.id }) {
                state.todos[index] = todo
            }
        case .store(.setTodoHidden(let todoId, let isHidden)):
            Self.setTodoHidden(&state, todoId: todoId, isHidden: isHidden)
        case .store(.appendTodos(let todos, let nextCursor)):
            state.todos.append(contentsOf: todos)
            state.nextCursor = nextCursor
        case .store(.resetPagination):
            state.todos = []
            state.nextCursor = nil
            state.hasMore = false
        case .store(.setHasMore(let value)):
            state.hasMore = value
        case .loading:
            break
        }

        return .none
    }

    func fetchEffect(
        query: TodoQuery,
        cursor: TodoCursor?,
        resetsPagination: Bool = true
    ) -> Effect<Action> {
        .concatenate(
            .send(.loading(.begin(target: .default, mode: .delayed))),
            .run { [fetchTodosUseCase] send in
                do {
                    let page = try await fetchTodosUseCase.execute(query, cursor: cursor)
                    if resetsPagination {
                        await send(.store(.resetPagination))
                    }
                    await send(.store(.appendTodos(
                        page.items.compactMap(TodoListItem.init(from:)),
                        nextCursor: page.nextCursor
                    )))
                    await send(.store(.setHasMore(page.items.count == query.pageSize && page.nextCursor != nil)))
                    await send(.loading(.end(target: .default, mode: .delayed)))
                } catch is CancellationError {
                    return
                } catch {
                    await send(.store(.setAlert(true)))
                    await send(.loading(.end(target: .default, mode: .delayed)))
                }
            }
        )
        .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }

    func setSearchTextEffect(state: inout State) -> Effect<Action> {
        state.showAllSearchResults = false
        let trimmed = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            state.searchResults = []
            return cancelSearchEffect()
        } else {
            return .concatenate(
                cancelSearchEffect(),
                debounceSearchEffect(trimmed)
            )
        }
    }

    func applySearchQueryEffect(_ query: String, state: inout State) -> Effect<Action> {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            state.searchResults = []
            return cancelSearchEffect()
        } else {
            return searchEffect(trimmed, category: state.category)
        }
    }

    func cancelSearchEffect() -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.debounce),
            .cancel(id: CancelID.request),
            .send(.loading(.end(target: .default, mode: .immediate)))
        )
    }

    func debounceSearchEffect(_ keyword: String) -> Effect<Action> {
        .concatenate(
            .send(.loading(.begin(target: .default, mode: .immediate))),
            .run { [clock, searchDebounceDelay] send in
                try await clock.sleep(for: searchDebounceDelay)
                await send(.store(.applySearchQuery(keyword)))
            }
            .cancellable(id: CancelID.debounce, cancelInFlight: true)
        )
    }
}
