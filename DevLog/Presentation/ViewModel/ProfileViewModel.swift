//
//  ProfileViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class ProfileViewModel: Store {
    enum ActivityType: String, CaseIterable, Hashable {
        case created
        case completed

        var title: String {
            switch self {
            case .created: return "생성"
            case .completed: return "완료"
            }
        }
    }

    struct CompletionDay: Hashable {
        let date: Date
        let createdCount: Int
        let completedCount: Int
        let isInMonth: Bool
    }

    struct CompletionMonth: Identifiable, Hashable {
        var id: Date { monthStart }
        let monthStart: Date
        let weeks: [[CompletionDay]]
    }

    struct CompletionQuarter: Identifiable, Hashable {
        let quarterStart: Date
        let months: [CompletionMonth]

        var id: Date { quarterStart }
    }

    struct State {
        var name: String = ""
        var email: String = ""
        var statusMessage: String = ""
        var avatarURL: URL?
        var selectedQuarterStart: Date?
        var completionQuarterCache: [Date: CompletionQuarter] = [:]
        var selectedActivityTypes: Set<ActivityType> = [.created, .completed]
        var showDoneButton: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var resetButtonEnabled: Bool {
            !statusMessage.isEmpty && showDoneButton
        }

        var selectedQuarter: CompletionQuarter? {
            guard let selectedQuarterStart else { return nil }
            return completionQuarterCache[selectedQuarterStart]
        }

        var canMoveToPreviousQuarter: Bool {
            guard let selectedQuarterStart else { return false }
            let calendar = Calendar.current
            guard let previousQuarterStart = calendar.date(byAdding: .month, value: -3, to: selectedQuarterStart) else {
                return false
            }
            let today = calendar.startOfDay(for: Date())
            return Self.canMove(to: previousQuarterStart, calendar: calendar, today: today)
        }

        var canMoveToNextQuarter: Bool {
            guard let selectedQuarterStart else { return false }
            let calendar = Calendar.current
            guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: selectedQuarterStart) else {
                return false
            }
            let today = calendar.startOfDay(for: Date())
            return Self.canMove(to: nextQuarterStart, calendar: calendar, today: today)
        }

        private static func canMove(to quarterStart: Date, calendar: Calendar, today: Date) -> Bool {
            guard let quarterEnd = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
                return false
            }
            let interval = DateInterval(start: quarterStart, end: quarterEnd)
            return interval.contains(today) || quarterEnd <= today
        }
    }

    enum Action {
        case onAppear
        case setAlert(Bool)
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case fetchUserData(UserProfile)
        case setCompletionQuarter(CompletionQuarter)
        case moveQuarter(Int)
        case toggleActivityType(ActivityType)
        case updateStatusMessage(String)
        case updateStatusTextFieldFocus(Bool)
    }

    enum SideEffect {
        case fetchUserData
        case fetchCompletionQuarter(Date)
        case updateStatusMessage(String)
        case updateHeatmapActivityTypes(Set<ActivityType>)
    }

    @Published private(set) var state = State()
    private let fetchUserDataUseCase: FetchUserDataUseCase
    private let fetchTodosByDateRangeUseCase: FetchTodosByDateRangeUseCase
    private let upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    private let fetchHeatmapActivityTypesUseCase: FetchProfileHeatmapActivityTypesUseCase
    private let updateHeatmapActivityTypesUseCase: UpdateProfileHeatmapActivityTypesUseCase

    init(
        fetchUserDataUseCase: FetchUserDataUseCase,
        fetchTodosByDateRangeUseCase: FetchTodosByDateRangeUseCase,
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase,
        fetchHeatmapActivityTypesUseCase: FetchProfileHeatmapActivityTypesUseCase,
        updateHeatmapActivityTypesUseCase: UpdateProfileHeatmapActivityTypesUseCase
    ) {
        self.fetchUserDataUseCase = fetchUserDataUseCase
        self.fetchTodosByDateRangeUseCase = fetchTodosByDateRangeUseCase
        self.upsertStatusMessageUseCase = upsertStatusMessageUseCase
        self.fetchHeatmapActivityTypesUseCase = fetchHeatmapActivityTypesUseCase
        self.updateHeatmapActivityTypesUseCase = updateHeatmapActivityTypesUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []
        switch action {
        case .onAppear:
            let calendar = Calendar.current
            if state.selectedQuarterStart == nil {
                state.selectedQuarterStart = quarterStart(for: Date(), calendar: calendar)
            }
            let rawValues = fetchHeatmapActivityTypesUseCase.execute()
            let settings = normalizeActivityTypes(rawValues)
            if !settings.isEmpty {
                state.selectedActivityTypes = settings
            }
            effects = [.fetchUserData]
            if let selectedQuarterStart = state.selectedQuarterStart,
               state.completionQuarterCache[selectedQuarterStart] == nil {
                effects.append(.fetchCompletionQuarter(selectedQuarterStart))
            }
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .tapResetStatusMessageButton:
            state.statusMessage = ""
        case .fetchUserData(let profile):
            state.name = profile.name
            state.email = profile.email
            state.statusMessage = profile.statusMessage
            state.avatarURL = profile.avatarURL
        case .setCompletionQuarter(let quarter):
            state.completionQuarterCache[quarter.quarterStart] = quarter
        case .moveQuarter(let delta):
            guard let selectedQuarterStart = state.selectedQuarterStart else { break }
            let calendar = Calendar.current
            let monthDelta = 3 * delta
            guard let nextQuarterStart = calendar.date(
                byAdding: .month,
                value: monthDelta,
                to: selectedQuarterStart
            ) else { break }
            let today = calendar.startOfDay(for: Date())
            guard canMove(to: nextQuarterStart, calendar: calendar, today: today) else { break }

            state.selectedQuarterStart = nextQuarterStart
            if state.completionQuarterCache[nextQuarterStart] == nil {
                effects = [.fetchCompletionQuarter(nextQuarterStart)]
            }
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
            let message = self.state.statusMessage
            effects = [.updateStatusMessage(message)]
        case .updateStatusMessage(let message):
            state.statusMessage = message
        case .updateStatusTextFieldFocus(let focused):
            state.showDoneButton = focused
        }
        self.state = state
        return effects
    }

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
        case .fetchCompletionQuarter(let quarterStart):
            Task {
                do {
                    let todos = try await fetchQuarterTodos(from: quarterStart)
                    let months = makeCompletionMonths(from: todos, quarterStart: quarterStart)
                    let quarter = CompletionQuarter(quarterStart: quarterStart, months: months)
                    send(.setCompletionQuarter(quarter))
                } catch {
                    let months = makeCompletionMonths(from: [], quarterStart: quarterStart)
                    let quarter = CompletionQuarter(quarterStart: quarterStart, months: months)
                    send(.setCompletionQuarter(quarter))
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
            let rawValues = ActivityType.allCases
                .filter { activityTypes.contains($0) }
                .map(\.rawValue)
            updateHeatmapActivityTypesUseCase.execute(rawValues)
        }
    }
}

private extension ProfileViewModel {
    func fetchQuarterTodos(from quarterStart: Date) async throws -> [Todo] {
        let calendar = Calendar.current
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
            return []
        }

        return try await fetchTodosByDateRangeUseCase.execute(
            from: quarterStart,
            to: nextQuarterStart
        )
    }

    func canMove(to quarterStart: Date, calendar: Calendar, today: Date) -> Bool {
        guard let quarterEnd = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
            return false
        }
        let interval = DateInterval(start: quarterStart, end: quarterEnd)
        return interval.contains(today) || quarterEnd <= today
    }

    func normalizeActivityTypes(_ rawValues: [String]) -> Set<ActivityType> {
        Set(rawValues.compactMap(ActivityType.init(rawValue:)))
    }

    func makeCompletionMonths(from todos: [Todo], quarterStart: Date) -> [CompletionMonth] {
        let calendar = Calendar.current
        var dailyCreatedCount: [Date: Int] = [:]
        var dailyCompletedCount: [Date: Int] = [:]

        for todo in todos {
            let createdDay = calendar.startOfDay(for: todo.createdAt)
            dailyCreatedCount[createdDay, default: 0] += 1

            if todo.isCompleted {
                let completedDay = calendar.startOfDay(for: todo.updatedAt)
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
    ) -> CompletionMonth {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart),
              let monthLastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, for: monthLastDay) else {
            return CompletionMonth(monthStart: monthStart, weeks: [])
        }

        var days: [CompletionDay] = []
        var cursor = firstWeekInterval.start
        while cursor < lastWeekInterval.end {
            let normalizedDate = calendar.startOfDay(for: cursor)
            let isInMonth = calendar.isDate(normalizedDate, equalTo: monthStart, toGranularity: .month)
            let createdCount = isInMonth ? (createdCounts[normalizedDate] ?? 0) : 0
            let completedCount = isInMonth ? (completedCounts[normalizedDate] ?? 0) : 0
            days.append(
                CompletionDay(
                    date: normalizedDate,
                    createdCount: createdCount,
                    completedCount: completedCount,
                    isInMonth: isInMonth
                )
            )
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        var weeks: [[CompletionDay]] = []
        var index = 0
        while index < days.count {
            let endIndex = min(index + 7, days.count)
            weeks.append(Array(days[index..<endIndex]))
            index += 7
        }

        return CompletionMonth(monthStart: monthStart, weeks: weeks)
    }

    func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return calendar.startOfDay(for: date)
        }
        return monthInterval.start
    }

    func quarterStart(for date: Date, calendar: Calendar) -> Date {
        let month = calendar.component(.month, from: date)
        let startMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = startMonth
        components.day = 1
        return calendar.date(from: components) ?? startOfMonth(for: date, calendar: calendar)
    }

    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }
}
