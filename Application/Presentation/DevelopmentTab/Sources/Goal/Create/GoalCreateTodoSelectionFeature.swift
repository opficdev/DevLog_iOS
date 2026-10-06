//
//  GoalCreateTodoSelectionFeature.swift
//  Development
//
//  Created by opfic on 9/20/26.
//

import Core
import Domain
import PresentationShared

@Reducer
struct GoalCreateTodoSelectionFeature {
    @ObservableState
    struct State: Equatable {
        var todos = [Todo]()
        var selectedTodoIDs: Set<String>
        var searchText = ""
        var isLoading = false
        var hasLoadFailure = false

        init(selectedTodoIDs: Set<String>) {
            self.selectedTodoIDs = selectedTodoIDs
        }

        var filteredTodos: [Todo] {
            guard !searchText.isEmpty else { return todos }
            return todos.filter { todo in
                todo.title.localizedCaseInsensitiveContains(searchText)
                    || String(todo.number).localizedCaseInsensitiveContains(searchText)
            }
        }

        var sections: [GoalTodoSelectionSectionItem] {
            goalTodoSelectionSections(from: filteredTodos)
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case view(ViewAction)
        case store(StoreAction)
        case delegate(Delegate)

        enum ViewAction: Equatable {
            case clearSelection
            case close
            case fetch
            case retry
            case save
            case toggleTodo(String)
        }

        enum StoreAction: Equatable {
            case loadedTodos([Todo])
            case todosFailed
        }

        enum Delegate: Equatable {
            case close
            case selected(Set<String>)
        }
    }

    @Dependency(\.developmentFetchTodosUseCase) private var fetchTodosUseCase

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                break
            case .view(.clearSelection):
                state.selectedTodoIDs.removeAll()
            case .view(.close):
                return .send(.delegate(.close))
            case .view(.fetch), .view(.retry):
                guard !state.isLoading else { break }
                state.isLoading = true
                state.hasLoadFailure = false
                return fetchTodosEffect()
            case .view(.save):
                return .send(.delegate(.selected(state.selectedTodoIDs)))
            case .view(.toggleTodo(let todoID)):
                guard state.todos.contains(where: { $0.id == todoID }) else { break }
                if state.selectedTodoIDs.contains(todoID) {
                    state.selectedTodoIDs.remove(todoID)
                } else {
                    state.selectedTodoIDs.insert(todoID)
                }
            case .store(.loadedTodos(let todos)):
                state.todos = todos
                state.isLoading = false
                state.hasLoadFailure = false
            case .store(.todosFailed):
                state.isLoading = false
                state.hasLoadFailure = true
            }

            return .none
        }
    }
}

private extension GoalCreateTodoSelectionFeature {
    func fetchTodosEffect() -> Effect<Action> {
        .run { [fetchTodosUseCase] send in
            do {
                let page = try await fetchTodosUseCase.execute(
                    TodoQuery(
                        sortTarget: .updatedAt,
                        sortOrder: .latest,
                        pageSize: 100,
                        fetchAllPages: true
                    ),
                    cursor: nil
                )
                await send(.store(.loadedTodos(page.items)))
            } catch {
                await send(.store(.todosFailed))
            }
        }
    }
}
