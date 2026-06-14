//
//  TodayFeatureTestDoubles.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/14/26.
//

import Foundation
import ComposableArchitecture
import DevLogCore
import DevLogDomain
@testable import DevLogPresentation

enum TodayTestError: Error {
    case failure
}

enum TodayTestSectionScope: Hashable, CaseIterable {
    case all
    case focused
    case overdue
    case dueSoon
}

enum TodayTestSectionCategory: Hashable {
    case later
    case unscheduled
    case focused
    case overdue
    case dueSoon
}

struct TodayDisplayedSection: Equatable {
    let category: TodayTestSectionCategory
    let itemIds: [String]
}

@MainActor
protocol TodayStateDriving {
    var todos: [TodayTodoItem] { get }
    var selectedSectionScope: TodayTestSectionScope { get }
    var displayOptions: TodayDisplayOptions { get }
    var showAlert: Bool { get }
    var isLoading: Bool { get }
    var displayedSections: [TodayDisplayedSection] { get }
    var summaryCounts: [TodayTestSectionScope: Int] { get }

    func fetchData() async
    func setSectionScope(_ scope: TodayTestSectionScope) async
    func setDueDateVisibility(_ visibility: TodayDisplayOptions.DueDateVisibility) async
    func setFocusVisibility(_ visibility: TodayDisplayOptions.FocusVisibility) async
    func resetDisplayOptions() async
    func completeTodo(_ item: TodayTodoItem) async
    func togglePinned(_ item: TodayTodoItem) async
}

@MainActor
struct TodayViewModelTestAdapter: TodayStateDriving {
    private let viewModel: TodayViewModel

    var todos: [TodayTodoItem] { viewModel.state.todos }
    var selectedSectionScope: TodayTestSectionScope { viewModel.state.selectedSectionScope.testValue }
    var displayOptions: TodayDisplayOptions { viewModel.state.displayOptions }
    var showAlert: Bool { viewModel.state.showAlert }
    var isLoading: Bool { viewModel.state.isLoading }
    var displayedSections: [TodayDisplayedSection] { viewModel.sections.map(\.testValue) }
    var summaryCounts: [TodayTestSectionScope: Int] {
        Dictionary(
            uniqueKeysWithValues: TodayTestSectionScope.allCases.map { scope in
                (scope, viewModel.summaryValue(for: scope.viewModelValue))
            }
        )
    }

    init(
        fetchUseCase: FetchTodosUseCase = TodayFetchTodosUseCaseSpy(),
        fetchTodoByIdUseCase: FetchTodoByIdUseCase = TodayFetchTodoByIdUseCaseSpy(),
        upsertUseCase: UpsertTodoUseCase = TodayUpsertTodoUseCaseSpy(),
        fetchDisplayOptionsUseCase: FetchTodayDisplayOptionsUseCase = TodayFetchDisplayOptionsUseCaseSpy(),
        updateDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase = TodayUpdateDisplayOptionsUseCaseSpy(),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase = TodayTrackAnalyticsEventUseCaseSpy()
    ) {
        viewModel = TodayViewModel(
            fetchTodosUseCase: fetchUseCase,
            fetchTodoByIdUseCase: fetchTodoByIdUseCase,
            upsertTodoUseCase: upsertUseCase,
            fetchTodayDisplayOptionsUseCase: fetchDisplayOptionsUseCase,
            updateTodayDisplayOptionsUseCase: updateDisplayOptionsUseCase,
            trackAnalyticsEventUseCase: trackAnalyticsEventUseCase
        )
    }

    func fetchData() async {
        viewModel.send(.fetchData)
    }

    func setSectionScope(_ scope: TodayTestSectionScope) async {
        viewModel.send(.setSectionScope(scope.viewModelValue))
    }

    func setDueDateVisibility(_ visibility: TodayDisplayOptions.DueDateVisibility) async {
        viewModel.send(.setDueDateVisibility(visibility))
    }

    func setFocusVisibility(_ visibility: TodayDisplayOptions.FocusVisibility) async {
        viewModel.send(.setFocusVisibility(visibility))
    }

    func resetDisplayOptions() async {
        viewModel.send(.resetDisplayOptions)
    }

    func completeTodo(_ item: TodayTodoItem) async {
        viewModel.send(.completeTodo(item))
    }

    func togglePinned(_ item: TodayTodoItem) async {
        viewModel.send(.togglePinned(item))
    }
}

@MainActor
struct TodayStoreTestAdapter: TodayStateDriving {
    private let store: TestStoreOf<TodayFeature>

    var todos: [TodayTodoItem] { store.state.todos }
    var selectedSectionScope: TodayTestSectionScope { store.state.selectedSectionScope.testValue }
    var displayOptions: TodayDisplayOptions { store.state.displayOptions }
    var showAlert: Bool { store.state.alert != nil }
    var isLoading: Bool { store.state.isLoading }
    var displayedSections: [TodayDisplayedSection] { store.state.sections.map(\.testValue) }
    var summaryCounts: [TodayTestSectionScope: Int] {
        Dictionary(
            uniqueKeysWithValues: store.state.summaryCounts.map { key, value in
                (key.testValue, value)
            }
        )
    }

    init(
        fetchUseCase: FetchTodosUseCase = TodayFetchTodosUseCaseSpy(),
        fetchTodoByIdUseCase: FetchTodoByIdUseCase = TodayFetchTodoByIdUseCaseSpy(),
        upsertUseCase: UpsertTodoUseCase = TodayUpsertTodoUseCaseSpy(),
        fetchDisplayOptionsUseCase: FetchTodayDisplayOptionsUseCase = TodayFetchDisplayOptionsUseCaseSpy(),
        updateDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase = TodayUpdateDisplayOptionsUseCaseSpy(),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase = TodayTrackAnalyticsEventUseCaseSpy(),
        configureDependencies: ((inout DependencyValues) -> Void)? = nil
    ) {
        store = TestStore(
            initialState: TodayFeature.State(
                displayOptions: fetchDisplayOptionsUseCase.execute()
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.todayFetchTodosUseCase = fetchUseCase
            $0.fetchTodoByIdUseCase = fetchTodoByIdUseCase
            $0.upsertTodoUseCase = upsertUseCase
            $0.updateTodayDisplayOptionsUseCase = updateDisplayOptionsUseCase
            $0.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
            $0.continuousClock = ContinuousClock()
            configureDependencies?(&$0)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func fetchData() async {
        await store.send(.fetchData)
        await drainReceivedActions()
    }

    func setSectionScope(_ scope: TodayTestSectionScope) async {
        await store.send(.setSectionScope(scope.featureValue))
    }

    func setDueDateVisibility(_ visibility: TodayDisplayOptions.DueDateVisibility) async {
        await store.send(.binding(.set(\.displayOptions.dueDateVisibility, visibility)))
        await drainReceivedActions()
    }

    func setFocusVisibility(_ visibility: TodayDisplayOptions.FocusVisibility) async {
        await store.send(.binding(.set(\.displayOptions.focusVisibility, visibility)))
        await drainReceivedActions()
    }

    func resetDisplayOptions() async {
        await store.send(.resetDisplayOptions)
        await drainReceivedActions()
    }

    func completeTodo(_ item: TodayTodoItem) async {
        await store.send(.completeTodo(item))
        await drainReceivedActions()
    }

    func togglePinned(_ item: TodayTodoItem) async {
        await store.send(.togglePinned(item))
        await drainReceivedActions()
    }

    private func drainReceivedActions() async {
        for _ in 0..<10 {
            await store.skipReceivedActions(strict: false)
        }
    }
}

private extension TodayViewModel.SectionScope {
    var testValue: TodayTestSectionScope {
        switch self {
        case .all:
            return .all
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }
}

private extension TodayTestSectionScope {
    var viewModelValue: TodayViewModel.SectionScope {
        switch self {
        case .all:
            return .all
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }

    var featureValue: TodayFeature.SectionScope {
        switch self {
        case .all:
            return .all
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }
}

private extension TodayFeature.SectionScope {
    var testValue: TodayTestSectionScope {
        switch self {
        case .all:
            return .all
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }
}

private extension TodayViewModel.SectionCategory {
    var testValue: TodayTestSectionCategory {
        switch self {
        case .later:
            return .later
        case .unscheduled:
            return .unscheduled
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }
}

private extension TodayFeature.SectionCategory {
    var testValue: TodayTestSectionCategory {
        switch self {
        case .later:
            return .later
        case .unscheduled:
            return .unscheduled
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }
}

private extension TodayViewModel.SectionContent {
    var testValue: TodayDisplayedSection {
        TodayDisplayedSection(
            category: category.testValue,
            itemIds: items.map(\.id)
        )
    }
}

private extension TodayFeature.SectionContent {
    var testValue: TodayDisplayedSection {
        TodayDisplayedSection(
            category: category.testValue,
            itemIds: items.map(\.id)
        )
    }
}
