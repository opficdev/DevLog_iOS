//
//  GoalDetailFeature.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

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
        let goalId: String
        var goal: DevelopmentGoal?
        var updatedGoalStatus: DevelopmentGoal.Status?
        var items = [RecordTimelineItem]()
        var isLoading = false
        var isTransitioning = false
        var hasLoaded = false
        var hasLoadFailure = false

        var goalTitle: String {
            goal?.title ?? ""
        }

        var goalStatus: DevelopmentGoal.Status? {
            updatedGoalStatus ?? goal?.status
        }

        var allowsRecordMutation: Bool {
            goalStatus == .inProgress
        }

        init(goalId: String) {
            self.goalId = goalId
        }
    }

    enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case view(ViewAction)
        case store(StoreAction)

        enum Alert: Equatable {
            case confirmTransition(DevelopmentGoal.Status)
        }

        enum ViewAction: Equatable {
            case fetch
            case refresh
            case selectStatus(DevelopmentGoal.Status)
        }

        enum StoreAction: Equatable {
            case loaded(goal: DevelopmentGoal, items: [RecordTimelineItem])
            case transitioned(DevelopmentGoal.Status)
            case failed
            case transitionFailed
        }
    }

    @Dependency(\.developmentFetchGoalUseCase) private var fetchGoalUseCase
    @Dependency(\.developmentFetchRecordsUseCase) private var fetchRecordsUseCase
    @Dependency(\.developmentFetchRecordVersionUseCase) private var fetchRecordVersionUseCase
    @Dependency(\.developmentUpdateGoalStatusUseCase) private var updateGoalStatusUseCase

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmTransition(let status))):
                guard !state.isTransitioning else { break }
                state.alert = nil
                state.isTransitioning = true
                return transitionEffect(goalId: state.goalId, status: status)
            case .alert:
                break
            case .view(.fetch):
                guard !state.hasLoaded, !state.isLoading else { break }
                state.isLoading = true
                state.hasLoadFailure = false
                return fetchEffect(goalId: state.goalId)
            case .view(.refresh):
                guard !state.isLoading else { break }
                state.isLoading = true
                state.hasLoadFailure = false
                return fetchEffect(goalId: state.goalId)
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
            case .store(.transitioned(let status)):
                state.updatedGoalStatus = status
                state.isTransitioning = false
            case .store(.failed):
                state.isLoading = false
                state.hasLoadFailure = true
                state.alert = Self.errorAlert
            case .store(.transitionFailed):
                state.isTransitioning = false
                state.alert = Self.transitionErrorAlert
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
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

    static func precedes(_ lhs: DevelopmentRecord, _ rhs: DevelopmentRecord) -> Bool {
        if lhs.createdAt == rhs.createdAt { return lhs.id < rhs.id }
        return lhs.createdAt < rhs.createdAt
    }

    static func canTransition(
        from currentStatus: DevelopmentGoal.Status,
        to status: DevelopmentGoal.Status
    ) -> Bool {
        switch (currentStatus, status) {
        case (.inProgress, .completed),
             (.inProgress, .archived),
             (.completed, .inProgress),
             (.archived, .inProgress):
            true
        default:
            false
        }
    }

    static func completionBlockingAlert(
        items: [RecordTimelineItem]
    ) -> AlertState<Action.Alert>? {
        guard !items.isEmpty else {
            return informationAlert(
                titleKey: "development_goal_completion_record_required_title",
                messageKey: "development_goal_completion_record_required_message"
            )
        }
        guard items.last?.isUnconfirmed == false else {
            return informationAlert(
                titleKey: "development_goal_completion_version_required_title",
                messageKey: "development_goal_completion_version_required_message"
            )
        }
        guard !items.contains(where: \.hasDraft) else {
            return informationAlert(
                titleKey: "development_goal_completion_draft_title",
                messageKey: "development_goal_completion_draft_message"
            )
        }
        return nil
    }

    static func transitionConfirmationAlert(
        _ status: DevelopmentGoal.Status
    ) -> AlertState<Action.Alert> {
        let keys: (title: String.LocalizationValue, message: String.LocalizationValue)
        switch status {
        case .inProgress:
            keys = (
                "development_goal_resume_alert_title",
                "development_goal_resume_alert_message"
            )
        case .completed:
            keys = (
                "development_goal_complete_alert_title",
                "development_goal_complete_alert_message"
            )
        case .archived:
            keys = (
                "development_goal_archive_alert_title",
                "development_goal_archive_alert_message"
            )
        }

        return AlertState {
            TextState(String(localized: keys.title, bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_cancel", bundle: PresentationResources.bundle))
            }
            ButtonState(action: .confirmTransition(status)) {
                TextState(String(
                    localized: transitionActionKey(status),
                    bundle: PresentationResources.bundle
                ))
            }
        } message: {
            TextState(String(localized: keys.message, bundle: PresentationResources.bundle))
        }
    }

    static var errorAlert: AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(
                localized: "development_record_timeline_error_message",
                bundle: PresentationResources.bundle
            ))
        }
    }

    static var transitionErrorAlert: AlertState<Action.Alert> {
        informationAlert(
            titleKey: "common_error_title",
            messageKey: "development_goal_transition_error_message"
        )
    }

    static func transitionActionKey(
        _ status: DevelopmentGoal.Status
    ) -> String.LocalizationValue {
        switch status {
        case .inProgress:
            "development_goal_resume"
        case .completed:
            "development_goal_complete"
        case .archived:
            "development_goal_archive"
        }
    }

    static func informationAlert(
        titleKey: String.LocalizationValue,
        messageKey: String.LocalizationValue
    ) -> AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: titleKey, bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: messageKey, bundle: PresentationResources.bundle))
        }
    }
}
