//
//  DevelopmentRecordTimelineFeature.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import Domain
import Foundation
import PresentationShared

struct DevelopmentRecordTimelineItem: Equatable, Identifiable {
    let record: DevelopmentRecord
    let currentVersion: DevelopmentRecord.Version?

    var id: String { record.id }
    var title: String { currentVersion?.title ?? record.draft?.title ?? "" }
    var isDraft: Bool { currentVersion == nil }
    var versionNumber: Int? { currentVersion?.number }
    var date: Date { currentVersion?.confirmedAt ?? record.draft?.updatedAt ?? record.createdAt }
}

@Reducer
struct DevelopmentRecordTimelineFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        let goalId: String
        var goalTitle = ""
        var items = [DevelopmentRecordTimelineItem]()
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
            case loaded(goalTitle: String, items: [DevelopmentRecordTimelineItem])
            case failed
        }
    }

    @Dependency(\.developmentFetchGoalUseCase) private var fetchGoalUseCase
    @Dependency(\.developmentFetchRecordsUseCase) private var fetchRecordsUseCase
    @Dependency(\.developmentFetchRecordHistoryUseCase) private var fetchRecordHistoryUseCase

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

extension DevelopmentRecordTimelineFeature {
    func fetchEffect(goalId: String) -> Effect<Action> {
        .run { [fetchGoalUseCase, fetchRecordsUseCase, fetchRecordHistoryUseCase] send in
            do {
                let goal = try await fetchGoalUseCase.execute(goalId)
                let records = try await fetchRecordsUseCase.execute(goalId: goalId)
                var items = [DevelopmentRecordTimelineItem]()

                for record in records.sorted(by: Self.precedes) {
                    let currentVersion: DevelopmentRecord.Version?
                    if let reference = record.currentVersion {
                        let versions = try await fetchRecordHistoryUseCase.execute(
                            goalId: goalId,
                            recordId: record.id
                        )
                        guard let version = versions.first(where: { $0.id == reference.id }) else {
                            throw DomainLayerError.developmentRecordVersionNotFound
                        }
                        currentVersion = version
                    } else {
                        currentVersion = nil
                    }
                    items.append(DevelopmentRecordTimelineItem(
                        record: record,
                        currentVersion: currentVersion
                    ))
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
