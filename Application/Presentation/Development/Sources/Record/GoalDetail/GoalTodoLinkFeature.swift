//
//  GoalTodoLinkFeature.swift
//  Development
//
//  Created by opfic on 9/15/26.
//

import Core
import Domain
import Foundation
import PresentationShared

struct TodoGoalLinkUpdate: Equatable, Sendable {
    let todoId: String
    let goalId: String?
}

@Reducer
struct GoalTodoLinkFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        let goalId: String
        var todos: [Todo]
        var selectedTodoIDs: Set<String>
        var searchText = ""
        var isLoading = false
        var isUpdating = false
        var hasLoadFailure = false

        init(goalId: String, todos: [Todo]) {
            self.goalId = goalId
            self.todos = todos
            self.selectedTodoIDs = Set(
                todos.lazy.filter { $0.goalId == goalId }.map(\.id)
            )
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

        var canClearSelection: Bool {
            !selectedTodoIDs.isEmpty && !isUpdating
        }

        var canSave: Bool {
            !isLoading && !hasLoadFailure && !isUpdating
        }
    }

    enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Never>)
        case binding(BindingAction<State>)
        case view(ViewAction)
        case store(StoreAction)
        case delegate(Delegate)

        enum ViewAction: Equatable {
            case close
            case clearSelection
            case retry
            case save
            case toggleTodo(String)
        }

        enum StoreAction: Equatable {
            case loadedTodos([Todo])
            case linksUpdated(Set<String>)
            case linkUpdateFailed
            case todosFailed
        }

        enum Delegate: Equatable {
            case close
            case saved([Todo])
        }
    }

    @Dependency(\.developmentFetchTodosUseCase) private var fetchTodosUseCase
    @Dependency(\.developmentUpdateTodoGoalUseCase) private var updateTodoGoalUseCase

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .alert, .binding, .delegate:
                break
            case .view(.close):
                return .send(.delegate(.close))
            case .view(.clearSelection):
                guard !state.isUpdating else { break }
                state.selectedTodoIDs.removeAll()
            case .view(.retry):
                guard !state.isLoading else { break }
                state.isLoading = true
                state.hasLoadFailure = false
                return fetchTodosEffect()
            case .view(.save):
                guard state.canSave else { break }
                let updates = Self.todoLinkUpdates(
                    todos: state.todos,
                    goalId: state.goalId,
                    selectedTodoIDs: state.selectedTodoIDs
                )
                guard !updates.isEmpty else {
                    return .send(.delegate(.saved(state.todos)))
                }
                state.isUpdating = true
                return updateTodoLinksEffect(
                    updates: updates,
                    selectedTodoIDs: state.selectedTodoIDs
                )
            case .view(.toggleTodo(let todoId)):
                guard !state.isUpdating,
                      state.todos.contains(where: { $0.id == todoId }) else { break }
                if state.selectedTodoIDs.contains(todoId) {
                    state.selectedTodoIDs.remove(todoId)
                } else {
                    state.selectedTodoIDs.insert(todoId)
                }
            case .store(.loadedTodos(let todos)):
                let goalId = state.goalId
                state.todos = todos
                state.selectedTodoIDs = Set(
                    todos.lazy.filter { $0.goalId == goalId }.map(\.id)
                )
                state.isLoading = false
                state.hasLoadFailure = false
            case .store(.linksUpdated(let selectedTodoIDs)):
                state.todos = state.todos.map { todo in
                    var todo = todo
                    if selectedTodoIDs.contains(todo.id) {
                        todo.goalId = state.goalId
                    } else if todo.goalId == state.goalId {
                        todo.goalId = nil
                    }
                    return todo
                }
                state.isUpdating = false
                return .send(.delegate(.saved(state.todos)))
            case .store(.linkUpdateFailed):
                state.isUpdating = false
                state.isLoading = true
                state.hasLoadFailure = false
                state.alert = Self.updateErrorAlert
                return fetchTodosEffect()
            case .store(.todosFailed):
                state.isLoading = false
                state.hasLoadFailure = true
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension GoalTodoLinkFeature {
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

    func updateTodoLinksEffect(
        updates: [TodoGoalLinkUpdate],
        selectedTodoIDs: Set<String>
    ) -> Effect<Action> {
        .run { [updateTodoGoalUseCase] send in
            do {
                for update in updates {
                    try await updateTodoGoalUseCase.execute(
                        todoId: update.todoId,
                        goalId: update.goalId
                    )
                }
                await send(.store(.linksUpdated(selectedTodoIDs)))
            } catch {
                await send(.store(.linkUpdateFailed))
            }
        }
    }

    static func todoLinkUpdates(
        todos: [Todo],
        goalId: String,
        selectedTodoIDs: Set<String>
    ) -> [TodoGoalLinkUpdate] {
        todos.compactMap { todo in
            let isLinked = todo.goalId == goalId
            let shouldLink = selectedTodoIDs.contains(todo.id)
            guard isLinked != shouldLink else { return nil }
            return TodoGoalLinkUpdate(
                todoId: todo.id,
                goalId: shouldLink ? goalId : nil
            )
        }
    }

    static var updateErrorAlert: AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(
                localized: "development_goal_todo_update_error_message",
                bundle: PresentationResources.bundle
            ))
        }
    }
}
