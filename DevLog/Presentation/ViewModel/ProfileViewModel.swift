//
//  ProfileViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation
import Combine

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
        var activityQuarter: ProfileActivityQuarter?
        var dayActivitiesByDate: [Date: [ProfileSelectedDayActivity]] = [:]
        var selectedActivityKinds: Set<ActivityKind> = [.created, .completed, .deleted]
        var selectedDay: ProfileActivityDay?
        var selectedActivityForSheet: ProfileSelectedDayActivity?
        var showDoneButton: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }

    enum Action {
        case onAppear
        case networkStatusChanged(Bool)
        case setLoading(Bool)
        case setAlert(Bool)
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case fetchUserData(UserProfile)
        case setActivityQuarter(
            quarterStart: Date,
            quarter: ProfileActivityQuarter
        )
        case setDayActivities(date: Date, activities: [ProfileSelectedDayActivity])
        case setEarliestQuarterStart(Date)
        case setQuarterPickerPresented(Bool)
        case setQuarterPickerYear(Int)
        case openQuarterPicker
        case selectQuarter(Date)
        case moveToCurrentQuarter
        case moveQuarter(Int)
        case toggleActivityKind(ActivityKind)
        case selectDay(ProfileActivityDay?)
        case setSelectedActivityForSheet(ProfileSelectedDayActivity?)
        case updateStatusMessage(String)
        case updateStatusTextFieldFocus(Bool)
    }

    enum SideEffect {
        case fetchUserData
        case fetchActivityQuarter(Date)
        case fetchDayActivities(Date)
        case updateStatusMessage(String)
        case updateHeatmapActivityKinds(Set<ActivityKind>)
    }

    private(set) var state = State()
    private let fetchUserDataUseCase: FetchUserDataUseCase
    private let fetchDailyActivitiesUseCase: FetchDailyActivitiesUseCase
    private let fetchDailyActivityEventsUseCase: FetchDailyActivityEventsUseCase
    private let fetchTodoCategoryPreferencesUseCase: FetchTodoCategoryPreferencesUseCase
    private let upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    private let networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    private let fetchHeatmapActivityTypesUseCase: FetchProfileHeatmapActivityTypesUseCase
    private let updateHeatmapActivityTypesUseCase: UpdateProfileHeatmapActivityTypesUseCase
    private let calendar = Calendar.current
    private let loadingState = LoadingState()
    private var cancellables = Set<AnyCancellable>()

    init(
        fetchUserDataUseCase: FetchUserDataUseCase,
        fetchDailyActivitiesUseCase: FetchDailyActivitiesUseCase,
        fetchDailyActivityEventsUseCase: FetchDailyActivityEventsUseCase,
        fetchTodoCategoryPreferencesUseCase: FetchTodoCategoryPreferencesUseCase,
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase,
        fetchHeatmapActivityTypesUseCase: FetchProfileHeatmapActivityTypesUseCase,
        updateHeatmapActivityTypesUseCase: UpdateProfileHeatmapActivityTypesUseCase
    ) {
        self.fetchUserDataUseCase = fetchUserDataUseCase
        self.fetchDailyActivitiesUseCase = fetchDailyActivitiesUseCase
        self.fetchDailyActivityEventsUseCase = fetchDailyActivityEventsUseCase
        self.fetchTodoCategoryPreferencesUseCase = fetchTodoCategoryPreferencesUseCase
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
        case .onAppear:
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
        case .setEarliestQuarterStart(let quarterStart):
            state.earliestQuarterStart = quarterStart
        case .setQuarterPickerPresented(let isPresented):
            state.showQuarterPicker = isPresented
        case .setQuarterPickerYear(let year):
            state.selectedQuarterPickerYear = year
        case .openQuarterPicker:
            if let selectedQuarterStart = state.selectedQuarterStart {
                state.selectedQuarterPickerYear = calendar.component(.year, from: selectedQuarterStart)
            }
            state.showQuarterPicker = true
        case .setActivityQuarter(let quarterStart, let quarter):
            guard state.selectedQuarterStart == quarterStart else { break }
            state.activityQuarter = quarter
            if state.selectedDay == nil {
                state.dayActivitiesByDate = [:]
            }
        case .setDayActivities(let date, let activities):
            state.dayActivitiesByDate[calendar.startOfDay(for: date)] = activities
        case .selectDay(let day):
            if let day, state.selectedDay?.date == day.date {
                state.selectedDay = nil
                state.selectedActivityForSheet = nil
            } else {
                state.selectedDay = day
                if let day {
                    effects = [.fetchDayActivities(day.date)]
                }
            }
        case .setSelectedActivityForSheet(let activity):
            state.selectedActivityForSheet = activity
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
            beginLoading(mode: .immediate)
            Task {
                do {
                    defer { endLoading(mode: .immediate) }
                    let activities = try await fetchQuarterActivities(from: quarterStart)
                    let months = makeActivityMonths(from: activities, quarterStart: quarterStart)
                    let quarter = ProfileActivityQuarter(quarterStart: quarterStart, months: months)
                    send(
                        .setActivityQuarter(
                            quarterStart: quarterStart,
                            quarter: quarter
                        )
                    )
                } catch {
                    send(.setAlert(true))
                }
            }
        case .fetchDayActivities(let date):
            beginLoading(mode: .delayed)
            Task {
                do {
                    defer { endLoading(mode: .delayed) }
                    let activities = try await fetchDayActivities(for: date)
                    send(.setDayActivities(date: date, activities: activities))
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

    var selectedDayActivities: [ProfileSelectedDayActivity] {
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
        state.selectedActivityForSheet = nil
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

    func fetchQuarterActivities(from quarterStart: Date) async throws -> [DailyActivity] {
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
            return []
        }

        return try await fetchDailyActivitiesUseCase.execute(
            from: dayKey(from: quarterStart),
            to: dayKey(from: calendar.date(byAdding: .day, value: -1, to: nextQuarterStart) ?? quarterStart)
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

    func makeActivityMonths(from activities: [DailyActivity], quarterStart: Date) -> [ProfileActivityMonth] {
        var dailyCreatedCount: [Date: Int] = [:]
        var dailyCompletedCount: [Date: Int] = [:]
        var dailyDeletedCount: [Date: Int] = [:]

        for activity in activities {
            guard let date = date(from: activity.dayKey) else { continue }
            let normalizedDate = calendar.startOfDay(for: date)
            dailyCreatedCount[normalizedDate] = activity.createdCount
            dailyCompletedCount[normalizedDate] = activity.completedCount
            dailyDeletedCount[normalizedDate] = activity.deletedCount
        }

        let monthStarts = (0..<3).compactMap {
            calendar.date(byAdding: .month, value: $0, to: quarterStart)
        }

        return monthStarts.map { monthStart in
            makeActivityMonth(
                monthStart: monthStart,
                createdCounts: dailyCreatedCount,
                completedCounts: dailyCompletedCount,
                deletedCounts: dailyDeletedCount,
                calendar: calendar
            )
        }
    }

    func makeActivityMonth(
        monthStart: Date,
        createdCounts: [Date: Int],
        completedCounts: [Date: Int],
        deletedCounts: [Date: Int],
        calendar: Calendar
    ) -> ProfileActivityMonth {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart),
              let monthLastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthLastDay) else {
            return ProfileActivityMonth(monthStart: monthStart, weeks: [])
        }

        var days: [ProfileActivityDay] = []
        var cursor = firstWeekInterval.start
        while cursor < lastWeekInterval.end {
            let normalizedDate = calendar.startOfDay(for: cursor)
            let isInMonth = calendar.isDate(normalizedDate, equalTo: monthStart, toGranularity: .month)
            let createdCount = isInMonth ? (createdCounts[normalizedDate] ?? 0) : 0
            let completedCount = isInMonth ? (completedCounts[normalizedDate] ?? 0) : 0
            let deletedCount = isInMonth ? (deletedCounts[normalizedDate] ?? 0) : 0
            days.append(
                ProfileActivityDay(
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

        var weeks: [[ProfileActivityDay]] = []
        var index = 0
        while index < days.count {
            let endIndex = min(index + 7, days.count)
            weeks.append(Array(days[index..<endIndex]))
            index += 7
        }

        return ProfileActivityMonth(monthStart: monthStart, weeks: weeks)
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

    func fetchDayActivities(for date: Date) async throws -> [ProfileSelectedDayActivity] {
        async let eventsTask = fetchDailyActivityEventsUseCase.execute(dayKey: dayKey(from: date))
        async let preferencesTask = fetchTodoCategoryPreferencesUseCase.execute()

        let (events, preferences) = try await (eventsTask, preferencesTask)
        let groupedEvents = Dictionary(grouping: events, by: \.todoId)

        return groupedEvents.values.compactMap { events in
            guard let firstEvent = events.first else { return nil }
            let activityKinds = orderedActivityKinds(from: events)

            return ProfileSelectedDayActivity(
                todoId: firstEvent.todoId,
                title: firstEvent.todoTitle,
                number: firstEvent.todoNumber,
                category: resolveCategory(id: firstEvent.todoCategoryID, preferences: preferences),
                activityKinds: activityKinds,
                isDeleted: events.contains { $0.isDeleted }
            )
        }
        .sorted()
    }

    func orderedActivityKinds(from events: [DailyActivityEvent]) -> [ActivityKind] {
        let activityKinds = Set(events.map(\.kind))
        let orderedActivityKinds: [ActivityKind] = [.created, .completed, .deleted]
        return orderedActivityKinds.filter { activityKinds.contains($0) }
    }

    func resolveCategory(
        id: String,
        preferences: [TodoCategoryPreference]
    ) -> TodoCategory {
        if let systemTodoCategory = SystemTodoCategory(rawValue: id) {
            return .system(systemTodoCategory)
        }

        if let userTodoCategory = preferences.compactMap({ preference in
            if case .user(let userTodoCategory) = preference.category {
                return userTodoCategory
            }
            return nil
        }).first(where: { $0.id == id }) {
            return .user(userTodoCategory)
        }

        return .system(.etc)
    }

    func dayKey(from date: Date) -> String {
        date.formatted(
            Date.ISO8601FormatStyle(timeZone: calendar.timeZone)
                .year()
                .month()
                .day()
        )
    }

    func date(from dayKey: String) -> Date? {
        try? Date(
            dayKey,
            strategy: Date.ISO8601FormatStyle(timeZone: calendar.timeZone)
                .year()
                .month()
                .day()
        )
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
