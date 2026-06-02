//
//  TodayViewModel.swift
//  DevLogPresentation
//
//  Created by opfic on 3/6/26.
//

import Foundation
import DevLogCore
import DevLogDomain

@Observable
public final class TodayViewModel: Store {
    public typealias DueDateVisibility = TodayDisplayOptions.DueDateVisibility
    public typealias FocusVisibility = TodayDisplayOptions.FocusVisibility

    // TodayView 상단에서 사용자가 선택하는 요약 탭 범위.
    public enum SectionScope: Hashable, CaseIterable {
        case all
        case focused
        case overdue
        case dueSoon
    }

    // 요약 탭 아래 실제 리스트에 렌더링되는 섹션 분류.
    public enum SectionCategory: Hashable {
        case later
        case unscheduled
        case focused
        case overdue
        case dueSoon
    }

    public struct SectionContent: Identifiable, Equatable {
        public var id: SectionCategory { category }
        public let category: SectionCategory
        public let title: String
        public let items: [TodayTodoItem]
    }

    public struct SectionCollection {
        public var focused: [TodayTodoItem] = []
        public var overdue: [TodayTodoItem] = []
        public var dueSoon: [TodayTodoItem] = []
        public var later: [TodayTodoItem] = []
        public var unscheduled: [TodayTodoItem] = []
    }

    public struct State: Equatable {
        public var todos: [TodayTodoItem] = []
        public var isLoading: Bool = false
        public var showAlert: Bool = false
        public var alertTitle: String = ""
        public var alertMessage: String = ""
        public var selectedSectionScope: SectionScope = .all
        public var displayOptions: TodayDisplayOptions = .default
    }

    public enum Action {
        case refresh
        case setAlert(Bool)
        case setSectionScope(SectionScope)
        case setDueDateVisibility(TodayDisplayOptions.DueDateVisibility)
        case setFocusVisibility(TodayDisplayOptions.FocusVisibility)
        case resetDisplayOptions
        case completeTodo(TodayTodoItem)
        case togglePinned(TodayTodoItem)
        case fetchData
        case fetchTodos([TodayTodoItem])
        case setLoading(Bool)
        case updateTodo(TodayTodoItem)
        case removeTodo(String)
    }

    public enum SideEffect {
        case fetchTodos
        case completeTodo(TodayTodoItem)
        case togglePinned(TodayTodoItem)
    }

    public private(set) var state = State()
    private let calendar = Calendar.current
    private let pageSize = 20
    private let upcomingWindowDays = 7
    private let fetchTodosUseCase: FetchTodosUseCase
    private let fetchTodoByIdUseCase: FetchTodoByIdUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let updateTodayDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase
    private let trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase
    private let loadingState = LoadingState()

    public init(
        fetchTodosUseCase: FetchTodosUseCase,
        fetchTodoByIdUseCase: FetchTodoByIdUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchTodayDisplayOptionsUseCase: FetchTodayDisplayOptionsUseCase,
        updateTodayDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase,
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase
    ) {
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchTodoByIdUseCase = fetchTodoByIdUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.updateTodayDisplayOptionsUseCase = updateTodayDisplayOptionsUseCase
        self.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
        self.state.displayOptions = fetchTodayDisplayOptionsUseCase.execute()
    }

    public var sections: [SectionContent] {
        let items = groupedSectionItems(from: displayedTodos)

        switch state.selectedSectionScope {
        case .all:
            return
                makeSection(
                    category: .focused,
                    title: String(localized: "today_section_focused"),
                    items: items.focused
                )
                + makeSection(
                    category: .overdue,
                    title: String(localized: "today_section_overdue"),
                    items: items.overdue
                )
                + makeSection(
                    category: .dueSoon,
                    title: String.localizedStringWithFormat(
                        String(localized: "today_section_due_soon_format"),
                        Int64(upcomingWindowDays)
                    ),
                    items: items.dueSoon
                )
                + makeSection(
                    category: .later,
                    title: String(localized: "today_section_later"),
                    items: items.later
                )
                + makeSection(
                    category: .unscheduled,
                    title: String(localized: "today_section_unscheduled"),
                    items: items.unscheduled
                )
        case .focused:
            return makeSection(
                category: .focused,
                title: String(localized: "today_section_focused"),
                items: items.focused
            )
        case .overdue:
            return makeSection(
                category: .overdue,
                title: String(localized: "today_section_overdue"),
                items: items.overdue
            )
        case .dueSoon:
            return makeSection(
                category: .dueSoon,
                title: String.localizedStringWithFormat(
                    String(localized: "today_section_due_soon_format"),
                    Int64(upcomingWindowDays)
                ),
                items: items.dueSoon
            )
        }
    }

    public func summaryValue(for scope: SectionScope) -> Int {
        switch scope {
        case .all:
            return displayedTodos.count
        case .focused:
            return displayedTodos.filter(\.isPinned).count
        case .overdue:
            return displayedTodos.filter(isOverdue).count
        case .dueSoon:
            return displayedTodos.filter(isDueSoon).count
        }
    }

    public func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .refresh, .setAlert, .setSectionScope, .setDueDateVisibility, .setFocusVisibility,
                .resetDisplayOptions, .completeTodo, .togglePinned:
            effects = reduceByUser(action, state: &state)
        case .fetchData:
            effects = reduceByView(action, state: &state)
        case .fetchTodos, .setLoading, .updateTodo, .removeTodo:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
        return effects
    }

    public func run(_ effect: SideEffect) {
        switch effect {
        case .fetchTodos:
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    async let todosWithDueDatePage = fetchTodosUseCase.execute(
                        TodoQuery(
                            completionFilter: .incomplete,
                            dueDateFilter: .withDueDate,
                            sortTarget: .dueDate,
                            sortOrder: .oldest,
                            pageSize: pageSize,
                            fetchAllPages: true
                        ),
                        cursor: nil
                    )
                    async let todosWithoutDueDatePage = fetchTodosUseCase.execute(
                        TodoQuery(
                            completionFilter: .incomplete,
                            dueDateFilter: .withoutDueDate,
                            sortTarget: .updatedAt,
                            sortOrder: .latest,
                            pageSize: pageSize,
                            fetchAllPages: true
                        ),
                        cursor: nil
                    )
                    let todosWithDueDate = try await todosWithDueDatePage.items.compactMap { TodayTodoItem(from: $0) }
                    let todosWithoutDueDate = try await todosWithoutDueDatePage.items.compactMap { TodayTodoItem(from: $0) }
                    send(.fetchTodos(todosWithDueDate + todosWithoutDueDate))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .completeTodo(let item):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    var todo = try await fetchTodoByIdUseCase.execute(item.id)
                    let now = Date()
                    todo.isCompleted = true
                    todo.completedAt = now
                    todo.updatedAt = now
                    try await upsertTodoUseCase.execute(todo)
                    trackAnalyticsEventUseCase.execute(.todoComplete)
                    send(.removeTodo(todo.id))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .togglePinned(let item):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    var todo = try await fetchTodoByIdUseCase.execute(item.id)
                    todo.isPinned.toggle()
                    todo.updatedAt = Date()
                    try await upsertTodoUseCase.execute(todo)
                    guard let todayTodoItem = TodayTodoItem(from: todo) else {
                        send(.setAlert(true))
                        return
                    }
                    send(.updateTodo(todayTodoItem))
                } catch {
                    send(.setAlert(true))
                }
            }
        }
    }
}

private extension TodayViewModel {
    func makeSection(
        category: SectionCategory,
        title: String,
        items: [TodayTodoItem]
    ) -> [SectionContent] {
        guard !items.isEmpty else { return [] }
        return [SectionContent(category: category, title: title, items: items)]
    }

    func reduceByUser(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .refresh:
            return [.fetchTodos]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .setSectionScope(let scope):
            if state.selectedSectionScope == scope, scope != .all {
                state.selectedSectionScope = .all
            } else {
                state.selectedSectionScope = scope
            }
        case .setDueDateVisibility(let visibility):
            state.displayOptions.dueDateVisibility = visibility
            updateTodayDisplayOptionsUseCase.execute(state.displayOptions)
        case .setFocusVisibility(let visibility):
            state.displayOptions.focusVisibility = visibility
            updateTodayDisplayOptionsUseCase.execute(state.displayOptions)
        case .resetDisplayOptions:
            state.displayOptions = .default
            updateTodayDisplayOptionsUseCase.execute(state.displayOptions)
        case .completeTodo(let item):
            return [.completeTodo(item)]
        case .togglePinned(let item):
            return [.togglePinned(item)]
        default:
            break
        }
        return []
    }

    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .fetchData:
            return [.fetchTodos]
        default:
            break
        }
        return []
    }

    func reduceByRun(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .fetchTodos(let items):
            state.todos = items
        case .setLoading(let isLoading):
            state.isLoading = isLoading
        case .updateTodo(let item):
            if let index = state.todos.firstIndex(where: { $0.id == item.id }) {
                state.todos[index] = item
            } else {
                state.todos.append(item)
            }
        case .removeTodo(let todoId):
            state.todos.removeAll { $0.id == todoId }
        default:
            break
        }
        return []
    }

    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }

    var displayedTodos: [TodayTodoItem] {
        let dueDateFilteredTodos: [TodayTodoItem]
        switch state.displayOptions.dueDateVisibility {
        case .all:
            dueDateFilteredTodos = state.todos
        case .withDueDateOnly:
            dueDateFilteredTodos = state.todos.filter { $0.dueDate != nil }
        case .withoutDueDateOnly:
            dueDateFilteredTodos = state.todos.filter { $0.dueDate == nil }
        }

        switch state.displayOptions.focusVisibility {
        case .all:
            return dueDateFilteredTodos
        case .focusedOnly:
            return dueDateFilteredTodos.filter(\.isPinned)
        }
    }

    func groupedSectionItems(
        from items: [TodayTodoItem]
    ) -> SectionCollection {
        let startOfToday = calendar.startOfDay(for: Date())
        guard let windowEnd = calendar.date(byAdding: .day, value: upcomingWindowDays, to: startOfToday) else {
            return SectionCollection(
                focused: items.filter(\.isPinned),
                unscheduled: items.filter { !$0.isPinned && $0.dueDate == nil }
            )
        }

        var collection = SectionCollection()

        for item in items {
            if item.isPinned {
                collection.focused.append(item)
                continue
            }

            guard let dueDate = item.dueDate else {
                collection.unscheduled.append(item)
                continue
            }

            let dueDay = calendar.startOfDay(for: dueDate)
            if dueDay < startOfToday {
                collection.overdue.append(item)
            } else if dueDay <= windowEnd {
                collection.dueSoon.append(item)
            } else {
                collection.later.append(item)
            }
        }

        return collection
    }

    func isOverdue(_ item: TodayTodoItem) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: Date())
    }

    private func beginLoading(_ mode: LoadingState.Mode) {
        loadingState.begin(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    private func endLoading(_ mode: LoadingState.Mode) {
        loadingState.end(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    func isDueSoon(_ item: TodayTodoItem) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        let startOfToday = calendar.startOfDay(for: Date())
        guard let windowEnd = calendar.date(byAdding: .day, value: upcomingWindowDays, to: startOfToday) else {
            return false
        }
        let dueDay = calendar.startOfDay(for: dueDate)
        return startOfToday <= dueDay && dueDay <= windowEnd
    }

}
