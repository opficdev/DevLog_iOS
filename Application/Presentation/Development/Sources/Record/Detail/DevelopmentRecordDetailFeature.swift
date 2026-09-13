//
//  DevelopmentRecordDetailFeature.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import Domain
import PresentationShared

@Reducer
struct DevelopmentRecordDetailFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        let goalTitle: String
        let record: DevelopmentRecord
        var currentVersion: DevelopmentRecord.Version?
        var isLoading = false
        var hasLoaded = false

        init(goalTitle: String, record: DevelopmentRecord) {
            self.goalTitle = goalTitle
            self.record = record
        }
    }

    enum Action: Equatable {
        case alert(PresentationAction<Never>)
        case view(ViewAction)
        case store(StoreAction)

        enum ViewAction: Equatable {
            case fetch
        }

        enum StoreAction: Equatable {
            case loaded(DevelopmentRecord.Version?)
            case failed
        }
    }

    @Dependency(\.developmentFetchRecordHistoryUseCase) private var fetchRecordHistoryUseCase

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .view(.fetch):
                guard !state.hasLoaded, !state.isLoading else { break }
                guard state.record.currentVersion != nil else {
                    state.hasLoaded = true
                    break
                }
                state.isLoading = true
                return fetchEffect(record: state.record)
            case .store(.loaded(let version)):
                state.currentVersion = version
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

private extension DevelopmentRecordDetailFeature {
    func fetchEffect(record: DevelopmentRecord) -> Effect<Action> {
        .run { [fetchRecordHistoryUseCase] send in
            do {
                let versions = try await fetchRecordHistoryUseCase.execute(
                    goalId: record.goalId,
                    recordId: record.id
                )
                guard let currentVersion = record.currentVersion,
                      let version = versions.first(where: { $0.id == currentVersion.id }) else {
                    throw DomainLayerError.developmentRecordVersionNotFound
                }
                await send(.store(.loaded(version)))
            } catch {
                await send(.store(.failed))
            }
        }
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
                localized: "development_record_detail_error_message",
                bundle: PresentationResources.bundle
            ))
        }
    }
}
