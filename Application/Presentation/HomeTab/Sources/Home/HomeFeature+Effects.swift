//
//  HomeFeature+Effects.swift
//  HomeTab
//
//  Created by opfic on 6/14/26.
//

import Combine
import Core
import Domain
import Foundation
import PresentationShared

extension HomeFeature {
    private enum CancelID: Hashable {
        case delayedTodoEditor
        case networkConnectivity
    }

    func observeNetworkConnectivityEffect() -> Effect<Action> {
        .publisher { [networkConnectivityUseCase] in
            networkConnectivityUseCase.observe()
                .map { .store(.networkStatusChanged($0)) }
        }
        .cancellable(id: CancelID.networkConnectivity, cancelInFlight: true)
    }

    func fetchTodoCategoryPreferencesEffect() -> Effect<Action> {
        .run { [fetchPreferencesUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.preferences.target, mode: .immediate)))
            do {
                let preferences = try await fetchPreferencesUseCase.execute()
                await send(.store(.setTodoCategory(preferences.map(TodoCategoryItem.init(from:)))))
            } catch {
                await send(.store(.setAlert(isPresented: true)))
            }
            await send(.loading(.end(target: LoadingTarget.preferences.target, mode: .immediate)))
        }
    }

    func fetchDevelopmentGoalsEffect() -> Effect<Action> {
        let goalsUseCase = fetchDevelopmentGoalsUseCase
        let recordsUseCase = fetchDevelopmentRecordsUseCase
        let versionUseCase = fetchDevelopmentRecordVersionUseCase

        return .run { [goalsUseCase, recordsUseCase, versionUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.developmentGoals.target, mode: .immediate)))
            do {
                let goals = try await goalsUseCase.execute(.init(status: .inProgress))
                let items = try await Self.makeDevelopmentGoalItems(
                    goals,
                    fetchRecordsUseCase: recordsUseCase,
                    fetchRecordVersionUseCase: versionUseCase
                )
                await send(.store(.developmentGoalsLoaded(items)))
            } catch {
                await send(.store(.developmentGoalsLoadFailed))
            }
            await send(.loading(.end(target: LoadingTarget.developmentGoals.target, mode: .immediate)))
        }
    }

    func trackTodoCreateEffect() -> Effect<Action> {
        .run { [trackAnalyticsEventUseCase] _ in
            trackAnalyticsEventUseCase.execute(.todoCreate)
        }
    }

    func updateTodoCategoryPreferencesEffect(_ items: [TodoCategoryItem]) -> Effect<Action> {
        .run { [updatePreferencesUseCase] send in
            do {
                try await updatePreferencesUseCase.execute(items.map(\.preference))
            } catch {
                await send(.store(.setAlert(isPresented: true)))
            }
        }
    }

    func delayedTodoEditorEffect() -> Effect<Action> {
        .run { [clock] send in
            // iOS 17에서 시트 dismiss 직후 fullScreenCover를 바로 올리지 않도록 하기 위해서 0.1초 딜레이
            try await clock.sleep(for: .seconds(0.1))
            await send(.store(.setPresentation(.todoEditor, true)))
        }
        .cancellable(id: CancelID.delayedTodoEditor, cancelInFlight: true)
    }

    static func setPresentation(
        _ state: inout State,
        presentation: Presentation,
        isPresented: Bool
    ) {
        switch presentation {
        case .todoEditor:
            state.fullScreenCover = isPresented ? state.selectedTodoCategory.map(FullScreenCoverState.todoEditor) : nil
            if !isPresented {
                state.selectedTodoCategory = nil
            }
        case .contentPicker:
            state.sheet = isPresented ? .contentPicker : state.showContentPicker ? nil : state.sheet
        case .searchView:
            state.fullScreenCover = isPresented ? .search : nil
        }
    }

    static func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        guard isPresented else {
            state.alert = nil
            return
        }

        state.alert = alertState()
    }

    static func alertState() -> AlertState<Never> {
        return AlertState<Never> {
            TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: "common_error_message", bundle: PresentationResources.bundle))
        }
    }

    static func makeDevelopmentGoalItems(
        _ goals: [DevelopmentGoal],
        fetchRecordsUseCase: FetchDevelopmentRecordsUseCase,
        fetchRecordVersionUseCase: FetchDevelopmentRecordVersionUseCase
    ) async throws -> [HomeDevelopmentGoalItem] {
        var items = [HomeDevelopmentGoalItem]()

        try await withThrowingTaskGroup(of: HomeDevelopmentGoalItem.self) { group in
            for goal in goals {
                group.addTask {
                    let records = try await fetchRecordsUseCase.execute(goalId: goal.id)
                    let recentRecord = try await makeRecentRecord(
                        goalId: goal.id,
                        records: records,
                        fetchRecordVersionUseCase: fetchRecordVersionUseCase
                    )
                    return HomeDevelopmentGoalItem(goal: goal, recentRecord: recentRecord)
                }
            }

            for try await item in group {
                items.append(item)
            }
        }

        return items.sorted { lhs, rhs in
            if lhs.goal.createdAt == rhs.goal.createdAt {
                return lhs.id < rhs.id
            }
            return lhs.goal.createdAt < rhs.goal.createdAt
        }
    }

    static func makeRecentRecord(
        goalId: String,
        records: [DevelopmentRecord],
        fetchRecordVersionUseCase: FetchDevelopmentRecordVersionUseCase
    ) async throws -> DevelopmentRecord.Version? {
        var versions = [DevelopmentRecord.Version]()

        try await withThrowingTaskGroup(of: DevelopmentRecord.Version.self) { group in
            for record in records {
                guard let currentVersion = record.currentVersion else { continue }
                group.addTask {
                    try await fetchRecordVersionUseCase.execute(
                        goalId: goalId,
                        recordId: record.id,
                        versionId: currentVersion.id
                    )
                }
            }

            for try await version in group {
                versions.append(version)
            }
        }

        return versions.max { $0.confirmedAt < $1.confirmedAt }
    }

}
