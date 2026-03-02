//
//  ProfileViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class ProfileViewModel: Store {
    struct State {
        var name: String = ""
        var email: String = ""
        var statusMessage: String = ""
        var avatarURL: URL?
        var selectedQuarterStart: Date?
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
        case setAlert(Bool)
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case fetchUserData(UserProfile)
        case setCompletionQuarter(
            quarterStart: Date,
            quarter: ProfileCompletionQuarter,
            dayActivitiesByDate: [Date: [ProfileSelectedDayActivity]]
        )
        case moveQuarter(Int)
        case toggleActivityType(ProfileActivityType)
        case selectDay(ProfileCompletionDay?)
        case setSelectedActivityForSheet(ProfileSelectedDayActivity?)
        case updateStatusMessage(String)
        case updateStatusTextFieldFocus(Bool)
    }

    enum SideEffect {
        case fetchUserData
        case fetchCompletionQuarter(Date)
        case updateStatusMessage(String)
        case updateHeatmapActivityTypes(Set<ProfileActivityType>)
    }

    @Published private(set) var state = State()
    private let fetchUserDataUseCase: FetchUserDataUseCase
    private let fetchTodosByDateRangeUseCase: FetchTodosByDateRangeUseCase
    private let upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    private let fetchHeatmapActivityTypesUseCase: FetchProfileHeatmapActivityTypesUseCase
    private let updateHeatmapActivityTypesUseCase: UpdateProfileHeatmapActivityTypesUseCase
    private let calendar = Calendar.current

    var quarterTitle: String {
        guard let start = state.selectedQuarterStart else { return "" }
        let year = calendar.component(.year, from: start)
        let month = calendar.component(.month, from: start)
        let quarter = ((month - 1) / 3) + 1
        return "\(year) Q\(quarter)"
    }

    var resetButtonEnabled: Bool {
        !state.statusMessage.isEmpty && state.showDoneButton
    }

    var selectedQuarter: ProfileCompletionQuarter? {
        state.completionQuarter
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

    // swiftlint:disable cyclomatic_complexity
    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []
        switch action {
        case .onAppear:
            if state.selectedQuarterStart == nil {
                guard let quarterStart = quarterStart(for: Date(), calendar: calendar) else { break }
                state.selectedQuarterStart = quarterStart
            }
            let rawValues = fetchHeatmapActivityTypesUseCase.execute()
            let settings = normalizeActivityTypes(rawValues)
            if !settings.isEmpty {
                state.selectedActivityTypes = settings
            }
            effects = [.fetchUserData]
            if let selectedQuarterStart = state.selectedQuarterStart {
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
        case .moveQuarter(let delta):
            guard let selectedQuarterStart = state.selectedQuarterStart else { break }
            let monthDelta = 3 * delta
            guard let nextQuarterStart = calendar.date(
                byAdding: .month,
                value: monthDelta,
                to: selectedQuarterStart
            ) else { break }
            let today = calendar.startOfDay(for: Date())
            guard canMove(to: nextQuarterStart, calendar: calendar, today: today) else { break }

            state.selectedQuarterStart = nextQuarterStart
            state.completionQuarter = nil
            state.dayActivitiesByDate = [:]
            state.selectedDay = nil
            state.selectedActivityForSheet = nil
            effects = [.fetchCompletionQuarter(nextQuarterStart)]
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

private extension ProfileViewModel {
    func makeDayActivitiesByDate(from todos: [Todo]) -> [Date: [ProfileSelectedDayActivity]] {
        var activitiesByDate: [Date: [ProfileSelectedDayActivity]] = [:]

        for todo in todos {
            let createdDay = calendar.startOfDay(for: todo.createdAt)
            let completedDay = todo.isCompleted ? calendar.startOfDay(for: todo.updatedAt) : nil

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
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }

    func fetchQuarterTodos(from quarterStart: Date) async throws -> [Todo] {
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

    func normalizeActivityTypes(_ rawValues: [String]) -> Set<ProfileActivityType> {
        Set(rawValues.compactMap(ProfileActivityType.init(rawValue:)))
    }

    func makeCompletionMonths(from todos: [Todo], quarterStart: Date) -> [ProfileCompletionMonth] {
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
                    isInMonth: isInMonth
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

    func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return calendar.startOfDay(for: date)
        }
        return monthInterval.start
    }

    func quarterStart(for date: Date, calendar: Calendar) -> Date? {
        let month = calendar.component(.month, from: date)
        let startMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = startMonth
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
        let today = calendar.startOfDay(for: Date())
        return canMove(to: targetQuarterStart, calendar: calendar, today: today)
    }
}
