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
        @Presents var alert: AlertState<Action.Alert>?
        let goalTitle: String
        let allowsMutation: Bool
        var record: DevelopmentRecord
        var versions = [DevelopmentRecord.Version]()
        var contentState: ContentState
        var currentVersionID: String?
        var isRestoring = false
        var restoreRequest: RestoreRequest?
        var restoredSourceVersionID: String?

        var isLoading: Bool {
            contentState == .idle || contentState == .loading
        }

        var currentVersion: DevelopmentRecord.Version? {
            versions.first { $0.id == currentVersionID }
        }

        init(
            goalTitle: String,
            record: DevelopmentRecord,
            allowsMutation: Bool = true
        ) {
            self.goalTitle = goalTitle
            self.allowsMutation = allowsMutation
            self.record = record
            self.currentVersionID = record.currentVersion?.id
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
        case loaded
        case failed
    }

    struct RestoreRequest: Equatable {
        let versionID: String
        let sourceVersionID: String
    }

    enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case view(ViewAction)
        case store(StoreAction)

        enum Alert: Equatable {
            case confirmRestore(DevelopmentRecord.Version)
        }

        enum ViewAction: Equatable {
            case fetch
            case restore(DevelopmentRecord.Version)
        }

        enum StoreAction: Equatable {
            case loaded(DevelopmentRecord, [DevelopmentRecord.Version])
            case restored(DevelopmentRecord.Version)
            case loadFailed
            case restoreFailed
        }
    }

    @Dependency(\.developmentFetchRecordsUseCase) private var fetchRecordsUseCase
    @Dependency(\.developmentFetchRecordHistoryUseCase) private var fetchRecordHistoryUseCase
    @Dependency(\.developmentRestoreRecordUseCase) private var restoreRecordUseCase
    @Dependency(\.uuid) private var uuid

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmRestore(let version))):
                state.alert = nil
                guard !state.isRestoring,
                      state.allowsMutation,
                      state.record.draft == nil,
                      version.id != state.currentVersionID else { break }
                let request = state.restoreRequest?.sourceVersionID == version.id
                    ? state.restoreRequest
                    : RestoreRequest(
                        versionID: uuid().uuidString,
                        sourceVersionID: version.id
                    )
                guard let request else { break }
                state.isRestoring = true
                state.restoreRequest = request
                state.restoredSourceVersionID = nil
                return restoreEffect(
                    goalID: state.record.goalId,
                    recordID: state.record.id,
                    request: request
                )
            case .alert:
                break
            case .view(.fetch):
                guard state.contentState != .loading,
                      !state.isRestoring,
                      state.record.currentVersion != nil else { break }
                state.alert = nil
                state.contentState = .loading
                state.restoredSourceVersionID = nil
                return fetchEffect(goalID: state.record.goalId, recordID: state.record.id)
            case .view(.restore(let version)):
                guard !state.isRestoring,
                      state.allowsMutation,
                      state.record.draft == nil,
                      version.id != state.currentVersionID else { break }
                state.alert = Self.restoreConfirmationAlert(version)
            case .store(.loaded(let record, let versions)):
                state.record = record
                state.versions = versions.sorted { $0.number < $1.number }
                state.currentVersionID = record.currentVersion?.id
                state.restoreRequest = nil
                state.contentState = .loaded
            case .store(.restored(let version)):
                if !state.versions.contains(where: { $0.id == version.id }) {
                    state.versions.append(version)
                    state.versions.sort { $0.number < $1.number }
                }
                state.currentVersionID = version.id
                state.restoredSourceVersionID = state.restoreRequest?.sourceVersionID
                state.restoreRequest = nil
                state.isRestoring = false
                state.contentState = .loaded
            case .store(.loadFailed):
                state.contentState = .failed
                state.alert = Self.errorAlert
            case .store(.restoreFailed):
                state.isRestoring = false
                state.alert = Self.restoreErrorAlert
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

private extension RecordDetailFeature {
    func fetchEffect(goalID: String, recordID: String) -> Effect<Action> {
        .run { [fetchRecordsUseCase, fetchRecordHistoryUseCase] send in
            do {
                async let recordValues = fetchRecordsUseCase.execute(goalId: goalID)
                async let versionValues = fetchRecordHistoryUseCase.execute(
                    goalId: goalID,
                    recordId: recordID
                )
                let (records, versions) = try await (recordValues, versionValues)
                guard let record = records.first(where: { $0.id == recordID }),
                      let currentVersion = record.currentVersion,
                      versions.contains(where: { $0.id == currentVersion.id }) else {
                    throw DomainLayerError.developmentRecordVersionNotFound
                }
                await send(.store(.loaded(record, versions)))
            } catch {
                await send(.store(.loadFailed))
            }
        }
    }

    func restoreEffect(
        goalID: String,
        recordID: String,
        request: RestoreRequest
    ) -> Effect<Action> {
        .run { [restoreRecordUseCase] send in
            do {
                let version = try await restoreRecordUseCase.execute(
                    goalId: goalID,
                    recordId: recordID,
                    versionId: request.versionID,
                    sourceVersionId: request.sourceVersionID
                )
                await send(.store(.restored(version)))
            } catch {
                await send(.store(.restoreFailed))
            }
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
                localized: "development_record_detail_error_message",
                bundle: PresentationResources.bundle
            ))
        }
    }

    static var restoreErrorAlert: AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(
                localized: "development_record_restore_error_message",
                bundle: PresentationResources.bundle
            ))
        }
    }
}

extension RecordDetailFeature {
    static func restoreConfirmationAlert(
        _ version: DevelopmentRecord.Version
    ) -> AlertState<Action.Alert> {
        AlertState {
            TextState(String(
                localized: "development_record_restore_alert_title",
                bundle: PresentationResources.bundle
            ))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_cancel", bundle: PresentationResources.bundle))
            }
            ButtonState(action: .confirmRestore(version)) {
                TextState(String(
                    localized: "development_record_restore_alert_confirm",
                    bundle: PresentationResources.bundle
                ))
            }
        } message: {
            TextState(String.localizedStringWithFormat(
                String(
                    localized: "development_record_restore_alert_message_format",
                    bundle: PresentationResources.bundle
                ),
                RecordPresentation.versionLabel(version.number)
            ))
        }
    }
}
