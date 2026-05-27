//
//  ProfileViewModel.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation
import Combine
import DevLogCore
import DevLogDomain

@Observable
final class ProfileViewModel: Store {
    struct State: Equatable {
        var name: String = ""
        var email: String = ""
        var isNetworkConnected: Bool = true
        var isLoading: Bool = false
        var statusMessage: String = ""
        var avatarURL: URL?
        var earliestQuarterStart: Date?
        var selectedQuarterStart: Date?
        var showQuarterPicker: Bool = false
        var selectedQuarterPickerYear = Calendar.current.component(.year, from: Date())
        var activityQuarter: HeatmapQuarter?
        var dayActivitiesByDate: [Date: [HeatmapActivityItem]] = [:]
        var selectedActivityKinds: Set<ActivityKind> = [.created, .completed, .deleted]
        var selectedDay: HeatmapDay?
        var showDoneButton: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }

    enum Action {
        case fetchData, refresh
        case networkStatusChanged(Bool)
        case setLoading(Bool)
        case setAlert(Bool)
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case fetchUserData(UserProfile)
        case setActivityQuarter(
            quarterStart: Date,
            quarter: HeatmapQuarter,
            dayActivitiesByDate: [Date: [HeatmapActivityItem]]
        )
        case setQuarterPickerPresented(Bool)
        case setQuarterPickerYear(Int)
        case openQuarterPicker
        case selectQuarter(Date)
        case moveToCurrentQuarter
        case moveQuarter(Int)
        case toggleActivityKind(ActivityKind)
        case selectDay(HeatmapDay?)
        case updateStatusMessage(String)
        case updateStatusTextFieldFocus(Bool)
    }

    enum SideEffect {
        case fetchUserData
        case fetchActivityQuarter(Date)
        case updateStatusMessage(String)
        case updateHeatmapActivityKinds(Set<ActivityKind>)
    }

    private(set) var state = State()
    private let fetchUserDataUseCase: FetchUserDataUseCase
    private let fetchTodosUseCase: FetchTodosUseCase
    private let upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    private let networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    private let fetchHeatmapActivityTypesUseCase: FetchHeatmapActivityTypesUseCase
    private let updateHeatmapActivityTypesUseCase: UpdateHeatmapActivityTypesUseCase
    private let calendar = Calendar.current
    private let loadingState = LoadingState()
    private var cancellables = Set<AnyCancellable>()

    init(
        fetchUserDataUseCase: FetchUserDataUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase,
        fetchHeatmapActivityTypesUseCase: FetchHeatmapActivityTypesUseCase,
        updateHeatmapActivityTypesUseCase: UpdateHeatmapActivityTypesUseCase
    ) {
        self.fetchUserDataUseCase = fetchUserDataUseCase
        self.fetchTodosUseCase = fetchTodosUseCase
        self.upsertStatusMessageUseCase = upsertStatusMessageUseCase
        self.networkConnectivityUseCase = networkConnectivityUseCase
        self.fetchHeatmapActivityTypesUseCase = fetchHeatmapActivityTypesUseCase
        self.updateHeatmapActivityTypesUseCase = updateHeatmapActivityTypesUseCase
        setupNetworkObserving()
    }

    // swiftlint:disable cyclomatic_complexity
    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []
        switch action {
        case .fetchData, .refresh:
            if state.selectedQuarterStart == nil {
                guard let quarterStart = quarterStart(for: Date()) else { break }
                state.selectedQuarterStart = quarterStart
            }
            effects = [.fetchUserData]
            let rawValues = fetchHeatmapActivityTypesUseCase.execute()
            let settings = normalizeActivityKinds(rawValues)
            if !settings.isEmpty {
                state.selectedActivityKinds = settings
            }
            if let selectedQuarterStart = state.selectedQuarterStart {
                effects.append(.fetchActivityQuarter(selectedQuarterStart))
            }
        case .networkStatusChanged(let isConnected):
            state.isNetworkConnected = isConnected
        case .setLoading(let isLoading):
            state.isLoading = isLoading
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .tapResetStatusMessageButton:
            state.statusMessage = ""
        case .fetchUserData(let profile):
            state.name = profile.name
            state.email = profile.email
            state.statusMessage = profile.statusMessage
            state.avatarURL = profile.avatarURL
            if state.earliestQuarterStart == nil {
                state.earliestQuarterStart = quarterStart(for: profile.createdAt)
                    ?? calendar.startOfDay(for: profile.createdAt)
            }
        case .setQuarterPickerPresented(let isPresented):
            state.showQuarterPicker = isPresented
        case .setQuarterPickerYear(let year):
            state.selectedQuarterPickerYear = year
        case .openQuarterPicker:
            if let selectedQuarterStart = state.selectedQuarterStart {
                state.selectedQuarterPickerYear = calendar.component(.year, from: selectedQuarterStart)
            }
            state.showQuarterPicker = true
        case .setActivityQuarter(let quarterStart, let quarter, let dayActivitiesByDate):
            guard state.selectedQuarterStart == quarterStart else { break }
            state.activityQuarter = quarter
            state.dayActivitiesByDate = dayActivitiesByDate
        case .selectDay(let day):
            if let day, state.selectedDay?.date == day.date {
                state.selectedDay = nil
            } else {
                state.selectedDay = day
            }
        case .selectQuarter(let quarterStart):
            guard canSelectQuarter(quarterStart) else { break }
            state.showQuarterPicker = false
            updateSelectedQuarter(to: quarterStart, state: &state, effects: &effects)
        case .moveToCurrentQuarter:
            guard let currentQuarterStart = quarterStart(for: Date()),
                  state.selectedQuarterStart != currentQuarterStart else { break }
            updateSelectedQuarter(to: currentQuarterStart, state: &state, effects: &effects)
        case .moveQuarter(let delta):
            guard let selectedQuarterStart = state.selectedQuarterStart else { break }
            let monthDelta = 3 * delta
            guard let nextQuarterStart = calendar.date(
                byAdding: .month,
                value: monthDelta,
                to: selectedQuarterStart
            ) else { break }
            guard canSelectQuarter(nextQuarterStart) else { break }
            updateSelectedQuarter(to: nextQuarterStart, state: &state, effects: &effects)
        case .toggleActivityKind(let activityKind):
            if state.selectedActivityKinds.contains(activityKind), state.selectedActivityKinds.count == 1 {
                break
            }

            if state.selectedActivityKinds.contains(activityKind) {
                state.selectedActivityKinds.remove(activityKind)
            } else {
                state.selectedActivityKinds.insert(activityKind)
            }
            effects = [.updateHeatmapActivityKinds(state.selectedActivityKinds)]
        case .willUpdateStatusMessage:
            if !state.isNetworkConnected { break }
            let message = self.state.statusMessage
            effects = [.updateStatusMessage(message)]
        case .updateStatusMessage(let message):
            state.statusMessage = message
        case .updateStatusTextFieldFocus(let focused):
            state.showDoneButton = focused
        }
        if self.state != state { self.state = state }
        return effects
    }
    // swiftlint:enable cyclomatic_complexity

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchUserData:
            Task {
                do {
                    let profile = try await fetchUserDataUseCase.execute()
                    send(.fetchUserData(profile))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .fetchActivityQuarter(let quarterStart):
            beginLoading(mode: .delayed)
            Task {
                do {
                    defer { endLoading(mode: .delayed) }
                    let quarterActivityData = try await fetchQuarterActivityData(from: quarterStart)
                    send(
                        .setActivityQuarter(
                            quarterStart: quarterStart,
                            quarter: quarterActivityData.quarter,
                            dayActivitiesByDate: quarterActivityData.dayActivitiesByDate
                        )
                    )
                } catch {
                    send(.setAlert(true))
                }
            }
        case .updateStatusMessage(let message):
            Task {
                do {
                    try await upsertStatusMessageUseCase.execute(message)
                } catch {
                    send(.setAlert(true))
                }
            }
        case .updateHeatmapActivityKinds(let activityKinds):
            let rawValues = ActivityKindItem.selectableItems
                .map(\.rawValue)
                .filter { rawValue in
                    guard let activityKind = ActivityKind(rawValue: rawValue) else {
                        return false
                    }
                    return activityKinds.contains(activityKind)
                }
            updateHeatmapActivityTypesUseCase.execute(rawValues)
        }
    }
}

private struct HeatmapActivityCounts {
    var createdCount = 0
    var completedCount = 0
    var deletedCount = 0

    mutating func increment(_ activityKind: ActivityKind) {
        switch activityKind {
        case .created:
            createdCount += 1
        case .completed:
            completedCount += 1
        case .deleted:
            deletedCount += 1
        }
    }
}

private struct HeatmapActivityEntry {
    var todo: Todo
    var activityKinds: Set<ActivityKind>
}

extension ProfileViewModel {
    private func setupNetworkObserving() {
        networkConnectivityUseCase.observe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.send(.networkStatusChanged(isConnected))
            }
            .store(in: &cancellables)
    }

    var quarterTitle: String {
        guard let start = state.selectedQuarterStart else { return "" }
        let year = calendar.component(.year, from: start)
        let month = calendar.component(.month, from: start)
        let quarter = ((month - 1) / 3) + 1
        return String.localizedStringWithFormat(
            String(localized: "profile_year_quarter_format"),
            String(year),
            String(quarter)
        )
    }

    var selectedDayActivities: [HeatmapActivityItem] {
        guard let selectedDay = state.selectedDay else { return [] }
        let dayStart = calendar.startOfDay(for: selectedDay.date)
        let activities = state.dayActivitiesByDate[dayStart] ?? []

        return activities.filter { activity in
            !Set(activity.activityKinds).isDisjoint(with: state.selectedActivityKinds)
        }
    }

    var canMoveToPreviousQuarter: Bool {
        canMoveToQuarter(offsetMonths: -3)
    }

    var canMoveToNextQuarter: Bool {
        canMoveToQuarter(offsetMonths: 3)
    }

    var isViewingCurrentQuarter: Bool {
        guard let selectedQuarterStart = state.selectedQuarterStart,
              let currentQuarterStart = quarterStart(for: Date()) else {
            return false
        }
        return selectedQuarterStart == currentQuarterStart
    }

    var availableQuarterYears: [Int] {
        guard let earliestQuarterStart = state.earliestQuarterStart,
              let currentQuarterStart = quarterStart(for: Date()) else { return [state.selectedQuarterPickerYear] }
        let earliestYear = calendar.component(.year, from: earliestQuarterStart)
        let currentYear = calendar.component(.year, from: currentQuarterStart)
        return Array(stride(from: currentYear, through: earliestYear, by: -1))
    }

    func quarterStartForPicker(quarter: Int) -> Date? {
        quarterStart(year: state.selectedQuarterPickerYear, quarter: quarter)
    }

    func isQuarterSelectableForPicker(_ quarter: Int) -> Bool {
        guard let quarterStart = quarterStartForPicker(quarter: quarter) else { return false }
        return canSelectQuarter(quarterStart)
    }

    func isQuarterSelectedForPicker(_ quarter: Int) -> Bool {
        quarterStartForPicker(quarter: quarter) == state.selectedQuarterStart
    }
}

private extension ProfileViewModel {
    func updateSelectedQuarter(
        to quarterStart: Date,
        state: inout State,
        effects: inout [SideEffect]
    ) {
        guard state.selectedQuarterStart != quarterStart else { return }
        state.selectedQuarterStart = quarterStart
        state.activityQuarter = nil
        state.dayActivitiesByDate = [:]
        state.selectedDay = nil
        effects = [.fetchActivityQuarter(quarterStart)]
    }

    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }

    func fetchQuarterActivityData(
        from quarterStart: Date
    ) async throws -> (quarter: HeatmapQuarter, dayActivitiesByDate: [Date: [HeatmapActivityItem]]) {
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
            return (HeatmapQuarter(quarterStart: quarterStart, months: []), [:])
        }

        async let createdTodoPage = fetchTodosUseCase.execute(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: .createdAt,
                pageSize: 100,
                fetchAllPages: true
            ),
            cursor: nil
        )
        async let completedTodoPage = fetchTodosUseCase.execute(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: .completedAt,
                pageSize: 100,
                fetchAllPages: true
            ),
            cursor: nil
        )
        async let deletedTodoPage = fetchTodosUseCase.execute(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: .deletedAt,
                pageSize: 100,
                fetchAllPages: true
            ),
            cursor: nil
        )

        let (createdTodoPageResult, completedTodoPageResult, deletedTodoPageResult) = try await (
            createdTodoPage,
            completedTodoPage,
            deletedTodoPage
        )
        return makeQuarterActivityData(
            createdTodos: createdTodoPageResult.items,
            completedTodos: completedTodoPageResult.items,
            deletedTodos: deletedTodoPageResult.items,
            quarterStart: quarterStart
        )
    }

    func canSelectQuarter(_ quarterStart: Date) -> Bool {
        guard let earliestQuarterStart = state.earliestQuarterStart,
              let currentQuarterStart = self.quarterStart(for: Date()) else { return false }
        return earliestQuarterStart <= quarterStart && quarterStart <= currentQuarterStart
    }

    func normalizeActivityKinds(_ rawValues: [String]) -> Set<ActivityKind> {
        let selectableActivityKindRawValues = Set(ActivityKindItem.selectableItems.map(\.rawValue))

        return Set(
            rawValues
                .compactMap(ActivityKind.init(rawValue:))
                .filter { selectableActivityKindRawValues.contains($0.rawValue) }
        )
    }

    func makeActivityMonths(
        dailyCountsByDate: [Date: HeatmapActivityCounts],
        quarterStart: Date
    ) -> [HeatmapMonth] {
        let monthStarts = (0..<3).compactMap {
            calendar.date(byAdding: .month, value: $0, to: quarterStart)
        }

        return monthStarts.map { monthStart in
            makeActivityMonth(
                monthStart: monthStart,
                dailyCountsByDate: dailyCountsByDate,
                calendar: calendar
            )
        }
    }

    func makeActivityMonth(
        monthStart: Date,
        dailyCountsByDate: [Date: HeatmapActivityCounts],
        calendar: Calendar
    ) -> HeatmapMonth {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart),
              let monthLastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthLastDay) else {
            return HeatmapMonth(monthStart: monthStart, weeks: [])
        }

        var days: [HeatmapDay] = []
        var cursor = firstWeekInterval.start
        while cursor < lastWeekInterval.end {
            let normalizedDate = calendar.startOfDay(for: cursor)
            let isInMonth = calendar.isDate(normalizedDate, equalTo: monthStart, toGranularity: .month)
            let dailyCounts = dailyCountsByDate[normalizedDate] ?? HeatmapActivityCounts()
            let createdCount = isInMonth ? dailyCounts.createdCount : 0
            let completedCount = isInMonth ? dailyCounts.completedCount : 0
            let deletedCount = isInMonth ? dailyCounts.deletedCount : 0
            days.append(
                HeatmapDay(
                    date: normalizedDate,
                    createdCount: createdCount,
                    completedCount: completedCount,
                    deletedCount: deletedCount,
                    isVisible: isInMonth
                )
            )
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        var weeks: [[HeatmapDay]] = []
        var index = 0
        while index < days.count {
            let endIndex = min(index + 7, days.count)
            weeks.append(Array(days[index..<endIndex]))
            index += 7
        }

        return HeatmapMonth(monthStart: monthStart, weeks: weeks)
    }

    func quarterStart(for date: Date) -> Date? {
        let month = calendar.component(.month, from: date)
        let startMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = startMonth
        components.day = 1
        return calendar.date(from: components)
    }

    func quarterStart(year: Int, quarter: Int) -> Date? {
        guard (1...4).contains(quarter) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = ((quarter - 1) * 3) + 1
        components.day = 1
        return calendar.date(from: components)
    }

    func canMoveToQuarter(offsetMonths: Int) -> Bool {
        guard let selectedQuarterStart = state.selectedQuarterStart else { return false }
        guard let targetQuarterStart = calendar.date(
            byAdding: .month, value: offsetMonths, to: selectedQuarterStart)
        else {
            return false
        }
        return canSelectQuarter(targetQuarterStart)
    }

    func makeQuarterActivityData(
        createdTodos: [Todo],
        completedTodos: [Todo],
        deletedTodos: [Todo],
        quarterStart: Date
    ) -> (quarter: HeatmapQuarter, dayActivitiesByDate: [Date: [HeatmapActivityItem]]) {
        var dailyCountsByDate: [Date: HeatmapActivityCounts] = [:]
        var activityEntriesByDate: [Date: [String: HeatmapActivityEntry]] = [:]

        for todo in createdTodos {
            appendHeatmapActivity(
                todo: todo,
                kind: .created,
                occurredAt: todo.createdAt,
                dailyCountsByDate: &dailyCountsByDate,
                activityEntriesByDate: &activityEntriesByDate
            )
        }

        for todo in completedTodos {
            guard let completedAt = todo.completedAt else { continue }
            appendHeatmapActivity(
                todo: todo,
                kind: .completed,
                occurredAt: completedAt,
                dailyCountsByDate: &dailyCountsByDate,
                activityEntriesByDate: &activityEntriesByDate
            )
        }

        for todo in deletedTodos {
            guard let deletedAt = todo.deletedAt else { continue }
            appendHeatmapActivity(
                todo: todo,
                kind: .deleted,
                occurredAt: deletedAt,
                dailyCountsByDate: &dailyCountsByDate,
                activityEntriesByDate: &activityEntriesByDate
            )
        }

        let quarter = HeatmapQuarter(
            quarterStart: quarterStart,
            months: makeActivityMonths(dailyCountsByDate: dailyCountsByDate, quarterStart: quarterStart)
        )
        let dayActivitiesByDate = activityEntriesByDate.mapValues { activityEntries in
            activityEntries.values.compactMap { activityEntry in
                HeatmapActivityItem(
                    todo: activityEntry.todo,
                    activityKinds: orderedActivityKinds(from: activityEntry.activityKinds)
                )
            }
            .sorted()
        }
        return (quarter, dayActivitiesByDate)
    }

    func appendHeatmapActivity(
        todo: Todo,
        kind: ActivityKind,
        occurredAt: Date,
        dailyCountsByDate: inout [Date: HeatmapActivityCounts],
        activityEntriesByDate: inout [Date: [String: HeatmapActivityEntry]]
    ) {
        let dayStart = calendar.startOfDay(for: occurredAt)
        var heatmapActivityCounts = dailyCountsByDate[dayStart] ?? HeatmapActivityCounts()
        heatmapActivityCounts.increment(kind)
        dailyCountsByDate[dayStart] = heatmapActivityCounts

        var activityEntries = activityEntriesByDate[dayStart] ?? [:]
        var heatmapActivityEntry = activityEntries[todo.id] ?? HeatmapActivityEntry(todo: todo, activityKinds: [])
        heatmapActivityEntry.todo = todo
        heatmapActivityEntry.activityKinds.insert(kind)
        activityEntries[todo.id] = heatmapActivityEntry
        activityEntriesByDate[dayStart] = activityEntries
    }

    func orderedActivityKinds(from activityKinds: Set<ActivityKind>) -> [ActivityKind] {
        let orderedActivityKinds: [ActivityKind] = [.created, .completed, .deleted]
        return orderedActivityKinds.filter { activityKinds.contains($0) }
    }

    func beginLoading(mode: LoadingState.Mode) {
        loadingState.begin(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    func endLoading(mode: LoadingState.Mode) {
        loadingState.end(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }
}
