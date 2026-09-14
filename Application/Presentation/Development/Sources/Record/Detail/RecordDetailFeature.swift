//
//  RecordDetailFeature.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import Domain
import PresentationShared

@Reducer
struct RecordDetailFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        let goalTitle: String
        let record: DevelopmentRecord
        var contentState: ContentState

        var isLoading: Bool {
            contentState == .idle || contentState == .loading
        }

        init(goalTitle: String, record: DevelopmentRecord) {
            self.goalTitle = goalTitle
            self.record = record
            if record.currentVersion == nil, let draft = record.draft {
                self.contentState = .draft(draft)
            } else {
                self.contentState = .idle
            }
        }
    }

    enum ContentState: Equatable {
        case idle
        case loading
        case draft(DevelopmentRecord.Draft)
        case confirmed(DevelopmentRecord.Version)
        case failed
    }

    enum Action: Equatable {
        case alert(PresentationAction<Never>)
        case view(ViewAction)
        case store(StoreAction)

        enum ViewAction: Equatable {
            case fetch
        }

        enum StoreAction: Equatable {
            case loaded(DevelopmentRecord.Version)
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
                guard state.contentState == .idle || state.contentState == .failed else { break }
                state.alert = nil
                state.contentState = .loading
                return fetchEffect(record: state.record)
            case .store(.loaded(let version)):
                state.contentState = .confirmed(version)
            case .store(.failed):
                state.contentState = .failed
                state.alert = Self.errorAlert
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

private extension RecordDetailFeature {
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
