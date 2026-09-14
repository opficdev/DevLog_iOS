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
    var title: String { currentVersion?.title ?? record.draft?.title ?? "" }
    var isDraft: Bool { currentVersion == nil }
    var versionNumber: Int? { currentVersion?.number }
    var date: Date { currentVersion?.confirmedAt ?? record.draft?.updatedAt ?? record.createdAt }
}

@Reducer
struct GoalDetailFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        let goalId: String
        var goalTitle = ""
        var items = [RecordTimelineItem]()
        var isLoading = false
        var hasLoaded = false

        init(goalId: String) {
            self.goalId = goalId
        }
    }

    enum Action: Equatable {
        case alert(PresentationAction<Never>)
        case view(ViewAction)
        case store(StoreAction)

        enum ViewAction: Equatable {
            case fetch
            case refresh
        }

        enum StoreAction: Equatable {
            case loaded(goalTitle: String, items: [RecordTimelineItem])
            case failed
        }
    }

    @Dependency(\.developmentFetchGoalUseCase) private var fetchGoalUseCase
    @Dependency(\.developmentFetchRecordsUseCase) private var fetchRecordsUseCase
    @Dependency(\.developmentFetchRecordVersionUseCase) private var fetchRecordVersionUseCase

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .view(.fetch):
                guard !state.hasLoaded, !state.isLoading else { break }
                state.isLoading = true
                return fetchEffect(goalId: state.goalId)
            case .view(.refresh):
                guard !state.isLoading else { break }
                state.isLoading = true
                return fetchEffect(goalId: state.goalId)
            case .store(.loaded(let goalTitle, let items)):
                state.goalTitle = goalTitle
                state.items = items
                state.isLoading = false
                state.hasLoaded = true
            case .store(.failed):
                state.isLoading = false
                state.alert = Self.errorAlert
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

                await send(.store(.loaded(goalTitle: goal.title, items: items)))
            } catch {
                await send(.store(.failed))
            }
        }
    }

    static func precedes(_ lhs: DevelopmentRecord, _ rhs: DevelopmentRecord) -> Bool {
        if lhs.createdAt == rhs.createdAt { return lhs.id < rhs.id }
        return lhs.createdAt < rhs.createdAt
    }

    static var errorAlert: AlertState<Never> {
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
}
