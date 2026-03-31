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
        var statusMessage: String = ""
        var avatarURL: URL?
        var earliestQuarterStart: Date?
        var selectedQuarterStart: Date?
        var showQuarterPicker: Bool = false
        var selectedQuarterPickerYear = Calendar.current.component(.year, from: Date())
        var completionQuarter: ProfileCompletionQuarter?
        var dayActivitiesByDate: [Date: [ProfileSelectedDayActivity]] = [:]
        var selectedActivityTypes: Set<ProfileActivityType> = [.created, .completed]
        var selectedDay: ProfileCompletionDay?
        var selectedActivityForSheet: ProfileSelectedDayActivity?
        var showDoneButton: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }

    enum Action {
        case onAppear
        case networkStatusChanged(Bool)
        case setAlert(Bool)
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case fetchUserData(UserProfile)
        case setCompletionQuarter(
            quarterStart: Date,
            quarter: ProfileCompletionQuarter,
            dayActivitiesByDate: [Date: [ProfileSelectedDayActivity]]
        )
        case setEarliestQuarterStart(Date)
        case setQuarterPickerPresented(Bool)
        case setQuarterPickerYear(Int)
        case openQuarterPicker
        case selectQuarter(Date)
        case moveToCurrentQuarter
        case moveQuarter(Int)
        case toggleActivityType(ProfileActivityType)
        case selectDay(ProfileCompletionDay?)
        case setSelectedActivityForSheet(ProfileSelectedDayActivity?)
        case updateStatusMessage(String)
        case updateStatusTextFieldFocus(Bool)
    }

    enum SideEffect {
        case fetchUserData
        case fetchEarliestQuarterStart
        case fetchCompletionQuarter(Date)
        case updateStatusMessage(String)
        case updateHeatmapActivityTypes(Set<ProfileActivityType>)
    }

    private(set) var state = State()
    private let fetchUserDataUseCase: FetchUserDataUseCase
    private let fetchTodosUseCase: FetchTodosUseCase
    private let upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    private let networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    private let fetchHeatmapActivityTypesUseCase: FetchProfileHeatmapActivityTypesUseCase
    private let updateHeatmapActivityTypesUseCase: UpdateProfileHeatmapActivityTypesUseCase
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()

    init(
        fetchUserDataUseCase: FetchUserDataUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase,
        fetchHeatmapActivityTypesUseCase: FetchProfileHeatmapActivityTypesUseCase,
        updateHeatmapActivityTypesUseCase: UpdateProfileHeatmapActivityTypesUseCase
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
        case .onAppear:
            if state.selectedQuarterStart == nil {
                guard let quarterStart = quarterStart(for: Date()) else { break }
                state.selectedQuarterStart = quarterStart
            }
            effects = [.fetchUserData]
            if state.earliestQuarterStart == nil {
                state.earliestQuarterStart = state.selectedQuarterStart
                effects.append(.fetchEarliestQuarterStart)
            }
            let rawValues = fetchHeatmapActivityTypesUseCase.execute()
            let settings = normalizeActivityTypes(rawValues)
            if !settings.isEmpty {
                state.selectedActivityTypes = settings
            }
            if let selectedQuarterStart = state.selectedQuarterStart {
                effects.append(.fetchCompletionQuarter(selectedQuarterStart))
            }
        case .networkStatusChanged(let isConnected):
            state.isNetworkConnected = isConnected
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .tapResetStatusMessageButton:
            state.statusMessage = ""
        case .fetchUserData(let profile):
            state.name = profile.name
            state.email = profile.email
            state.statusMessage = profile.statusMessage
            state.avatarURL = profile.avatarURL
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
        case .setCompletionQuarter(let quarterStart, let quarter, let dayActivitiesByDate):
            guard state.selectedQuarterStart == quarterStart else { break }
            state.completionQuarter = quarter
            state.dayActivitiesByDate = dayActivitiesByDate
        case .selectDay(let day):
            if let day, state.selectedDay?.date == day.date {
                state.selectedDay = nil
            } else {
                state.selectedDay = day
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
        case .toggleActivityType(let activityType):
            if state.selectedActivityTypes.contains(activityType), state.selectedActivityTypes.count == 1 {
                break
            }

            if state.selectedActivityTypes.contains(activityType) {
                state.selectedActivityTypes.remove(activityType)
            } else {
                state.selectedActivityTypes.insert(activityType)
            }
            effects = [.updateHeatmapActivityTypes(state.selectedActivityTypes)]
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
        case .fetchEarliestQuarterStart:
            Task {
                do {
                    let earliestQuarterStart = try await fetchEarliestQuarterStart()
                    send(.setEarliestQuarterStart(earliestQuarterStart))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .fetchCompletionQuarter(let quarterStart):
            Task {
                do {
                    let todos = try await fetchQuarterTodos(from: quarterStart)
                    let months = makeCompletionMonths(from: todos, quarterStart: quarterStart)
                    let quarter = ProfileCompletionQuarter(quarterStart: quarterStart, months: months)
                    let dayActivitiesByDate = makeDayActivitiesByDate(from: todos)
                    send(
                        .setCompletionQuarter(
                            quarterStart: quarterStart,
                            quarter: quarter,
                            dayActivitiesByDate: dayActivitiesByDate
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
        case .updateHeatmapActivityTypes(let activityTypes):
            let rawValues = ProfileActivityType.allCases
                .filter { activityTypes.contains($0) }
                .map(\.rawValue)
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
        return "\(year) Q\(quarter)"
    }

    var selectedDayActivities: [ProfileSelectedDayActivity] {
        guard let selectedDay = state.selectedDay else { return [] }
        let dayStart = calendar.startOfDay(for: selectedDay.date)
        let activities = state.dayActivitiesByDate[dayStart] ?? []

        return activities.filter { activity in
            (state.selectedActivityTypes.contains(.created) && activity.showsCreated)
            || (state.selectedActivityTypes.contains(.completed) && activity.showsCompleted)
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
        state.completionQuarter = nil
        state.dayActivitiesByDate = [:]
        state.selectedDay = nil
        state.selectedActivityForSheet = nil
        effects = [.fetchCompletionQuarter(quarterStart)]
    }

    func makeDayActivitiesByDate(from todos: [Todo]) -> [Date: [ProfileSelectedDayActivity]] {
        var activitiesByDate: [Date: [ProfileSelectedDayActivity]] = [:]

        for todo in todos {
            let createdDay = calendar.startOfDay(for: todo.createdAt)
            let completedDay = todo.completedAt.map { calendar.startOfDay(for: $0) }

            activitiesByDate[createdDay, default: []].append(
                ProfileSelectedDayActivity(
                    todo: todo,
                    showsCreated: true,
                    showsCompleted: completedDay == createdDay
                )
            )

            if let completedDay, completedDay != createdDay {
                activitiesByDate[completedDay, default: []].append(
                    ProfileSelectedDayActivity(
                        todo: todo,
                        showsCreated: false,
                        showsCompleted: true
                    )
                )
            }
        }

        return activitiesByDate
    }

    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }

    func fetchQuarterTodos(from quarterStart: Date) async throws -> [Todo] {
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
            return []
        }

        let page = try await fetchTodosUseCase.execute(
            TodoQuery(
                createdAtFrom: quarterStart,
                createdAtTo: nextQuarterStart,
                pageSize: 100,
                fetchAllPages: true
            ),
            cursor: nil
        )
        return page.items
    }

    func fetchEarliestQuarterStart() async throws -> Date {
        let page = try await fetchTodosUseCase.execute(
            TodoQuery(
                sortTarget: .createdAt,
                sortOrder: .oldest,
                pageSize: 1
            ),
            cursor: nil
        )
        let baseDate = page.items.first?.createdAt ?? Date()
        return quarterStart(for: baseDate) ?? calendar.startOfDay(for: baseDate)
    }

    func canSelectQuarter(_ quarterStart: Date) -> Bool {
        guard let earliestQuarterStart = state.earliestQuarterStart,
              let currentQuarterStart = self.quarterStart(for: Date()) else { return false }
        return earliestQuarterStart <= quarterStart && quarterStart <= currentQuarterStart
    }

    func normalizeActivityTypes(_ rawValues: [String]) -> Set<ProfileActivityType> {
        Set(rawValues.compactMap(ProfileActivityType.init(rawValue:)))
    }

    func makeCompletionMonths(from todos: [Todo], quarterStart: Date) -> [ProfileCompletionMonth] {
        var dailyCreatedCount: [Date: Int] = [:]
        var dailyCompletedCount: [Date: Int] = [:]

        for todo in todos {
            let createdDay = calendar.startOfDay(for: todo.createdAt)
            dailyCreatedCount[createdDay, default: 0] += 1

            if let completedAt = todo.completedAt {
                let completedDay = calendar.startOfDay(for: completedAt)
                dailyCompletedCount[completedDay, default: 0] += 1
            }
        }

        let monthStarts = (0..<3).compactMap {
            calendar.date(byAdding: .month, value: $0, to: quarterStart)
        }

        return monthStarts.map { monthStart in
            makeCompletionMonth(
                monthStart: monthStart,
                createdCounts: dailyCreatedCount,
                completedCounts: dailyCompletedCount,
                calendar: calendar
            )
        }
    }

    func makeCompletionMonth(
        monthStart: Date,
        createdCounts: [Date: Int],
        completedCounts: [Date: Int],
        calendar: Calendar
    ) -> ProfileCompletionMonth {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart),
              let monthLastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthLastDay) else {
            return ProfileCompletionMonth(monthStart: monthStart, weeks: [])
        }

        var days: [ProfileCompletionDay] = []
        var cursor = firstWeekInterval.start
        while cursor < lastWeekInterval.end {
            let normalizedDate = calendar.startOfDay(for: cursor)
            let isInMonth = calendar.isDate(normalizedDate, equalTo: monthStart, toGranularity: .month)
            let createdCount = isInMonth ? (createdCounts[normalizedDate] ?? 0) : 0
            let completedCount = isInMonth ? (completedCounts[normalizedDate] ?? 0) : 0
            days.append(
                ProfileCompletionDay(
                    date: normalizedDate,
                    createdCount: createdCount,
                    completedCount: completedCount,
                    isVisible: isInMonth
                )
            )
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        var weeks: [[ProfileCompletionDay]] = []
        var index = 0
        while index < days.count {
            let endIndex = min(index + 7, days.count)
            weeks.append(Array(days[index..<endIndex]))
            index += 7
        }

        return ProfileCompletionMonth(monthStart: monthStart, weeks: weeks)
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
}
