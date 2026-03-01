//
//  ProfileViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class ProfileViewModel: Store {
    enum HeatmapMetric: String, CaseIterable, Hashable {
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
        var completionQuarters: [CompletionQuarter] = []
        var selectedQuarterIndex: Int = 0
        var selectedMetrics: Set<HeatmapMetric> = [.created, .completed]
        var showDoneButton: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var resetButtonEnabled: Bool {
            !statusMessage.isEmpty && showDoneButton
        }

        var selectedQuarter: CompletionQuarter? {
            guard completionQuarters.indices.contains(selectedQuarterIndex) else { return nil }
            return completionQuarters[selectedQuarterIndex]
        }

        var canMoveToPreviousQuarter: Bool {
            selectedQuarterIndex > 0
        }

        var canMoveToNextQuarter: Bool {
            selectedQuarterIndex < completionQuarters.count - 1
        }
    }

    enum Action {
        case onAppear
        case setAlert(Bool)
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case fetchUserData(UserProfile)
        case setCompletionQuarters([CompletionQuarter])
        case moveQuarter(Int)
        case toggleHeatmapMetric(HeatmapMetric)
        case updateStatusMessage(String)
        case updateStatusTextFieldFocus(Bool)
    }

    enum SideEffect {
        case fetchUserData
        case fetchCompletionMonths
        case updateStatusMessage(String)
    }

    @Published private(set) var state = State()
    private let fetchUserDataUseCase: FetchUserDataUseCase
    private let fetchTodosByDateRangeUseCase: FetchTodosByDateRangeUseCase
    private let upsertStatusMessageUseCase: UpsertStatusMessageUseCase

    init(
        fetchUserDataUseCase: FetchUserDataUseCase,
        fetchTodosByDateRangeUseCase: FetchTodosByDateRangeUseCase,
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    ) {
        self.fetchUserDataUseCase = fetchUserDataUseCase
        self.fetchTodosByDateRangeUseCase = fetchTodosByDateRangeUseCase
        self.upsertStatusMessageUseCase = upsertStatusMessageUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []
        switch action {
        case .onAppear:
            effects = [.fetchUserData, .fetchCompletionMonths]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .tapResetStatusMessageButton:
            state.statusMessage = ""
        case .fetchUserData(let profile):
            state.name = profile.name
            state.email = profile.email
            state.statusMessage = profile.statusMessage
            state.avatarURL = profile.avatarURL
        case .setCompletionQuarters(let quarters):
            state.completionQuarters = quarters
            state.selectedQuarterIndex = max(0, quarters.count - 1)
        case .moveQuarter(let delta):
            let newIndex = state.selectedQuarterIndex + delta
            guard state.completionQuarters.indices.contains(newIndex) else { break }
            state.selectedQuarterIndex = newIndex
        case .toggleHeatmapMetric(let metric):
            if state.selectedMetrics.contains(metric), state.selectedMetrics.count == 1 {
                break
            }

            if state.selectedMetrics.contains(metric) {
                state.selectedMetrics.remove(metric)
            } else {
                state.selectedMetrics.insert(metric)
            }
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
        case .fetchCompletionMonths:
            Task {
                let calendar = Calendar.current
                let currentQuarterStart = quarterStart(for: Date(), calendar: calendar)
                do {
                    let todos = try await fetchAllTodos()
                    let months = makeCompletionMonths(from: todos, quarterStart: currentQuarterStart)
                    let quarter = CompletionQuarter(quarterStart: currentQuarterStart, months: months)
                    send(.setCompletionQuarters([quarter]))
                } catch {
                    let months = makeCompletionMonths(from: [], quarterStart: currentQuarterStart)
                    let quarter = CompletionQuarter(quarterStart: currentQuarterStart, months: months)
                    send(.setCompletionQuarters([quarter]))
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
        }
    }
}

private extension ProfileViewModel {
    func fetchAllTodos() async throws -> [Todo] {
        let calendar = Calendar.current
        let currentQuarterStart = quarterStart(for: Date(), calendar: calendar)
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: currentQuarterStart) else {
            return []
        }

        return try await fetchTodosByDateRangeUseCase.execute(
            from: currentQuarterStart,
            to: nextQuarterStart
        )
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
