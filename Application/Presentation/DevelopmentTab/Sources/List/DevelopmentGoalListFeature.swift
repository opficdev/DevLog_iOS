//
//  DevelopmentGoalListFeature.swift
//  DevelopmentTab
//
//  Created by opfic on 10/5/26.
//

import Domain
import Foundation
import PresentationShared

@Reducer
struct DevelopmentGoalListFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var sheet: SheetState?
        var goals = [DevelopmentGoal]()
        var selectedStatus = DevelopmentGoal.Status.inProgress
        var recentRecords = [String: RecentRecord]()
        var visibleGoalIDs = Set<String>()
        var hasLoaded = false
        var isLoading = false
        var hasLoadFailure = false
        var requestID = 0
        var recordRevision = 0

        var filteredGoals: [DevelopmentGoal] {
            goals.filter { $0.status == selectedStatus }
        }

        func count(for status: DevelopmentGoal.Status) -> Int {
            goals.count { $0.status == status }
        }
    }

    @ObservableState
    @CasePathable
    enum SheetState: Equatable {
        case create
        case detail(String)
    }

    enum RecentRecord: Equatable {
        case loading
        case loaded(DevelopmentRecord.Version?)
        case failed
    }

    enum Action: Equatable {
        case sheet(PresentationAction<Never>)
        case selected
        case refresh
        case retry
        case selectStatus(DevelopmentGoal.Status)
        case showCreate
        case showDetail(String)
        case goalCreated(DevelopmentGoal)
        case cardAppeared(String)
        case cardDisappeared(String)
        case goalsLoaded([DevelopmentGoal], requestID: Int)
        case goalsFailed(requestID: Int)
        case recentRecordLoaded(String, RecentRecord, revision: Int)
    }

    @Dependency(\.developmentTabFetchGoalsUseCase) private var goalsUseCase
    @Dependency(\.developmentTabFetchRecentRecordUseCase) private var recentRecordUseCase

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            reduce(action, state: &state)
        }
        .ifLet(\.$sheet, action: \.sheet) {
            EmptyReducer()
        }
    }

    private func reduce(_ action: Action, state: inout State) -> Effect<Action> {
        switch action {
        case .selected, .retry:
            return fetchGoals(state: &state, showsLoading: !state.hasLoaded)
        case .refresh:
            return fetchGoals(state: &state, showsLoading: false)
        case .sheet(.dismiss):
            state.sheet = nil
            return fetchGoals(state: &state, showsLoading: false)
        case .selectStatus(let status):
            state.selectedStatus = status
        case .showCreate:
            state.sheet = .create
        case .showDetail(let goalID):
            state.sheet = .detail(goalID)
        case .sheet:
            break
        case .goalCreated(let goal):
            state.requestID += 1
            state.isLoading = false
            state.hasLoadFailure = false
            state.hasLoaded = true
            state.selectedStatus = .inProgress
            state.goals.removeAll { $0.id == goal.id }
            state.goals.append(goal)
            state.goals = Self.sortedGoals(state.goals)
        case .cardAppeared(let goalID):
            state.visibleGoalIDs.insert(goalID)
            guard state.recentRecords[goalID] == nil,
                  state.goals.contains(where: { $0.id == goalID }) else { break }
            state.recentRecords[goalID] = .loading
            return fetchRecentRecord(goalID, revision: state.recordRevision)
        case .cardDisappeared(let goalID):
            state.visibleGoalIDs.remove(goalID)
        case .goalsLoaded(let goals, let requestID):
            guard requestID == state.requestID else { break }
            state.goals = Self.sortedGoals(goals)
            state.hasLoaded = true
            state.isLoading = false
            state.hasLoadFailure = false
            state.recordRevision += 1
            state.recentRecords.removeAll()
            state.visibleGoalIDs.formIntersection(goals.map(\.id))
            let effects = state.filteredGoals.compactMap { goal -> Effect<Action>? in
                guard state.visibleGoalIDs.contains(goal.id) else { return nil }
                state.recentRecords[goal.id] = .loading
                return fetchRecentRecord(goal.id, revision: state.recordRevision)
            }
            return .merge(effects)
        case .goalsFailed(let requestID):
            guard requestID == state.requestID else { break }
            state.isLoading = false
            state.hasLoadFailure = true
        case .recentRecordLoaded(let goalID, let recentRecord, let revision):
            guard revision == state.recordRevision,
                  state.goals.contains(where: { $0.id == goalID }) else { break }
            state.recentRecords[goalID] = recentRecord
        }
        return .none
    }

    private func fetchGoals(state: inout State, showsLoading: Bool) -> Effect<Action> {
        state.requestID += 1
        state.isLoading = showsLoading
        state.hasLoadFailure = false
        let requestID = state.requestID
        return .run { [goalsUseCase] send in
            do {
                let goals = try await goalsUseCase.execute(.init(status: nil))
                await send(.goalsLoaded(goals, requestID: requestID))
            } catch {
                await send(.goalsFailed(requestID: requestID))
            }
        }
    }

    private func fetchRecentRecord(_ goalID: String, revision: Int) -> Effect<Action> {
        .run { [recentRecordUseCase] send in
            do {
                let version = try await recentRecordUseCase.execute(goalId: goalID)
                await send(.recentRecordLoaded(goalID, .loaded(version), revision: revision))
            } catch {
                await send(.recentRecordLoaded(goalID, .failed, revision: revision))
            }
        }
    }

    private static func sortedGoals(_ goals: [DevelopmentGoal]) -> [DevelopmentGoal] {
        goals.sorted {
            if $0.createdAt == $1.createdAt { return $0.id < $1.id }
            return $0.createdAt < $1.createdAt
        }
    }
}
