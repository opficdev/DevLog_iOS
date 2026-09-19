//
//  GoalDetailFeature.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import Core
import Domain
import Foundation
import PresentationShared

struct RecordTimelineItem: Equatable, Identifiable {
    let record: DevelopmentRecord
    let currentVersion: DevelopmentRecord.Version?

    var id: String { record.id }
    var title: String { record.draft?.title ?? currentVersion?.title ?? "" }
    var hasDraft: Bool { record.draft != nil }
    var isUnconfirmed: Bool { currentVersion == nil }
    var versionNumber: Int? { hasDraft ? nil : currentVersion?.number }
    var date: Date { record.draft?.updatedAt ?? currentVersion?.confirmedAt ?? record.createdAt }
}

@Reducer
struct GoalDetailFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var todoLinkSheet: GoalTodoLinkFeature.State?
        let goalId: String
        var goal: DevelopmentGoal?
        var updatedGoalStatus: DevelopmentGoal.Status?
        var items = [RecordTimelineItem]()
        var todos = [Todo]()
        var linkedTodos = [Todo]()
        var isLoading = false
        var isTodoLoading = false
        var isTransitioning = false
        var hasLoaded = false
        var hasLoadedTodos = false
        var hasLoadFailure = false
        var hasTodoLoadFailure = false

        var goalTitle: String {
            goal?.title ?? ""
        }

        var goalStatus: DevelopmentGoal.Status? {
            updatedGoalStatus ?? goal?.status
        }

        var allowsRecordMutation: Bool {
            goalStatus == .inProgress
        }

        var allowsTodoLinkMutation: Bool {
            goalStatus == .inProgress
        }

        init(goalId: String) {
            self.goalId = goalId
        }
    }

    enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case todoLinkSheet(PresentationAction<GoalTodoLinkFeature.Action>)
        case binding(BindingAction<State>)
        case view(ViewAction)
        case store(StoreAction)

        enum Alert: Equatable {
            case confirmTransition(DevelopmentGoal.Status)
        }

        enum ViewAction: Equatable {
            case fetch
            case manageTodos
            case refresh
            case retryTodos
            case selectStatus(DevelopmentGoal.Status)
        }

        enum StoreAction: Equatable {
            case loaded(goal: DevelopmentGoal, items: [RecordTimelineItem])
            case loadedTodos([Todo])
            case transitioned(DevelopmentGoal.Status)
            case failed
            case todosFailed
            case transitionFailed
        }
    }

    @Dependency(\.developmentFetchGoalUseCase) private var fetchGoalUseCase
    @Dependency(\.developmentFetchRecordsUseCase) private var fetchRecordsUseCase
    @Dependency(\.developmentFetchRecordVersionUseCase) private var fetchRecordVersionUseCase
    @Dependency(\.developmentFetchTodosUseCase) private var fetchTodosUseCase
    @Dependency(\.developmentUpdateGoalStatusUseCase) private var updateGoalStatusUseCase

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmTransition(let status))):
                guard !state.isTransitioning else { break }
                state.alert = nil
                state.isTransitioning = true
                return transitionEffect(goalId: state.goalId, status: status)
            case .alert:
                break
            case .todoLinkSheet(.dismiss),
                 .todoLinkSheet(.presented(.delegate(.close))):
                state.todoLinkSheet = nil
            case .todoLinkSheet(.presented(.delegate(.saved(let todos)))):
                state.todos = todos
                state.linkedTodos = todos.filter { $0.goalId == state.goalId }
                state.todoLinkSheet = nil
            case .todoLinkSheet:
                break
            case .binding:
                break
            case .view(.fetch):
                guard !state.hasLoaded, !state.isLoading else { break }
                state.isLoading = true
                state.hasLoadFailure = false
                state.isTodoLoading = true
                state.hasTodoLoadFailure = false
                return .concatenate(
                    fetchEffect(goalId: state.goalId),
                    fetchTodosEffect()
                )
            case .view(.manageTodos):
                guard state.hasLoadedTodos,
                      state.allowsTodoLinkMutation,
                      !state.isTodoLoading,
                      state.todoLinkSheet == nil else { break }
                state.todoLinkSheet = GoalTodoLinkFeature.State(
                    goalId: state.goalId,
                    todos: state.todos
                )
            case .view(.refresh):
                guard !state.isLoading else { break }
                state.isLoading = true
                state.hasLoadFailure = false
                state.isTodoLoading = true
                state.hasTodoLoadFailure = false
                return .concatenate(
                    fetchEffect(goalId: state.goalId),
                    fetchTodosEffect()
                )
            case .view(.retryTodos):
                guard !state.isTodoLoading else { break }
                state.isTodoLoading = true
                state.hasTodoLoadFailure = false
                return fetchTodosEffect()
            case .view(.selectStatus(let status)):
                guard let goalStatus = state.goalStatus,
                      !state.isLoading,
                      !state.isTransitioning,
                      Self.canTransition(from: goalStatus, to: status) else { break }
                if status == .completed,
                   let alert = Self.completionBlockingAlert(items: state.items) {
                    state.alert = alert
                } else {
                    state.alert = Self.transitionConfirmationAlert(status)
                }
            case .store(.loaded(let goal, let items)):
                state.goal = goal
                state.updatedGoalStatus = nil
                state.items = items
                state.isLoading = false
                state.hasLoaded = true
                state.hasLoadFailure = false
            case .store(.loadedTodos(let todos)):
                state.todos = todos
                state.linkedTodos = todos.filter { $0.goalId == state.goalId }
                state.isTodoLoading = false
                state.hasLoadedTodos = true
                state.hasTodoLoadFailure = false
            case .store(.transitioned(let status)):
                state.updatedGoalStatus = status
                state.isTransitioning = false
            case .store(.failed):
                state.isLoading = false
                state.hasLoadFailure = true
                state.alert = Self.errorAlert
            case .store(.todosFailed):
                state.isTodoLoading = false
                state.hasTodoLoadFailure = true
            case .store(.transitionFailed):
                state.isTransitioning = false
                state.alert = Self.transitionErrorAlert
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$todoLinkSheet, action: \.todoLinkSheet) {
            GoalTodoLinkFeature()
        }
    }
}

extension GoalDetailFeature {
    func fetchEffect(goalId: String) -> Effect<Action> {
        .run { [fetchGoalUseCase, fetchRecordsUseCase, fetchRecordVersionUseCase] send in
            do {
                let goal = try await fetchGoalUseCase.execute(goalId)
                let records = try await fetchRecordsUseCase.execute(goalId: goalId)
                let sortedRecords = records.sorted(by: Self.precedes)
                var currentVersions = [DevelopmentRecord.Version?](
                    repeating: nil,
                    count: sortedRecords.count
                )

                try await withThrowingTaskGroup(
                    of: (Int, DevelopmentRecord.Version).self
                ) { group in
                    for (index, record) in sortedRecords.enumerated() {
                        guard let reference = record.currentVersion else { continue }
                        group.addTask {
                            let version = try await fetchRecordVersionUseCase.execute(
                                goalId: goalId,
                                recordId: record.id,
                                versionId: reference.id
                            )
                            return (index, version)
                        }
                    }

                    for try await (index, version) in group {
                        currentVersions[index] = version
                    }
                }

                let items = zip(sortedRecords, currentVersions).map { record, version in
                    RecordTimelineItem(
                        record: record,
                        currentVersion: version
                    )
                }

                await send(.store(.loaded(goal: goal, items: items)))
            } catch {
                await send(.store(.failed))
            }
        }
    }

    func transitionEffect(
        goalId: String,
        status: DevelopmentGoal.Status
    ) -> Effect<Action> {
        .run { [updateGoalStatusUseCase] send in
            do {
                try await updateGoalStatusUseCase.execute(goalId, to: status)
                await send(.store(.transitioned(status)))
            } catch {
                await send(.store(.transitionFailed))
            }
        }
    }

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
