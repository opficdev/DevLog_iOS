//
//  TodayViewModel.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation

@Observable
final class TodayViewModel: Store {
    enum SummaryScope: Hashable, CaseIterable {
        case all
        case focused
        case overdue
        case dueSoon
    }

    struct SectionContent: Identifiable, Equatable {
        var id: String { title }
        let title: String
        let items: [TodayTodoItem]
    }

    struct SectionBuckets {
        var focused: [TodayTodoItem] = []
        var overdue: [TodayTodoItem] = []
        var dueSoon: [TodayTodoItem] = []
        var later: [TodayTodoItem] = []
        var unscheduled: [TodayTodoItem] = []
    }

    struct State: Equatable {
        var todos: [TodayTodoItem] = []
        var isLoading: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var selectedSummaryScope: SummaryScope = .all
        var displayOptions: TodayDisplayOptions = .default
    }

    enum Action {
        case refresh
        case setAlert(Bool)
        case setSummaryScope(SummaryScope)
        case setDueDateVisibility(TodayDisplayOptions.DueDateVisibility)
        case setFocusVisibility(TodayDisplayOptions.FocusVisibility)
        case resetDisplayOptions
        case completeTodo(TodayTodoItem)
        case togglePinned(TodayTodoItem)
        case onAppear
        case fetchTodos([TodayTodoItem])
        case setLoading(Bool)
        case updateTodo(TodayTodoItem)
        case removeTodo(String)
    }

    enum SideEffect {
        case fetchTodos
        case completeTodo(TodayTodoItem)
        case togglePinned(TodayTodoItem)
    }

    private(set) var state = State()
    private let calendar = Calendar.current
    private let pageSize = 20
    private let upcomingWindowDays = 7
    private let fetchTodosUseCase: FetchTodosUseCase
    private let fetchTodoByIdUseCase: FetchTodoByIdUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase
    private let updateTodayDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase
    private let loadingState = LoadingState()

    init(
        fetchTodosUseCase: FetchTodosUseCase,
        fetchTodoByIdUseCase: FetchTodoByIdUseCase,
        upsertTodoUseCase: UpsertTodoUseCase,
        fetchTodayDisplayOptionsUseCase: FetchTodayDisplayOptionsUseCase,
        updateTodayDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase
    ) {
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchTodoByIdUseCase = fetchTodoByIdUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
        self.updateTodayDisplayOptionsUseCase = updateTodayDisplayOptionsUseCase
        self.state.displayOptions = fetchTodayDisplayOptionsUseCase.execute()
    }

    var sections: [SectionContent] {
        let groupedItems = groupedSectionItems(from: displayedTodos)
        let allSections: [SectionContent] = [
            SectionContent(title: "집중할 일", items: groupedItems.focused),
            SectionContent(title: "지난 마감", items: groupedItems.overdue),
            SectionContent(title: "\(upcomingWindowDays)일 내 일정", items: groupedItems.dueSoon),
            SectionContent(title: "나중 일정", items: groupedItems.later),
            SectionContent(title: "일정 미정", items: groupedItems.unscheduled)
        ]

        switch state.selectedSummaryScope {
        case .all:
            return allSections.filter { !$0.items.isEmpty }
        case .focused:
            return allSections.filter { $0.title == "집중할 일" && !$0.items.isEmpty }
        case .overdue:
            return allSections.filter { $0.title == "지난 마감" && !$0.items.isEmpty }
        case .dueSoon:
            return allSections.filter { $0.title == "\(upcomingWindowDays)일 내 일정" && !$0.items.isEmpty }
        }
    }

    func summaryValue(for scope: SummaryScope) -> Int {
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

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .refresh, .setAlert, .setSummaryScope, .setDueDateVisibility, .setFocusVisibility,
                .resetDisplayOptions, .completeTodo, .togglePinned:
            effects = reduceByUser(action, state: &state)
        case .onAppear:
            effects = reduceByView(action, state: &state)
        case .fetchTodos, .setLoading, .updateTodo, .removeTodo:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchTodos:
            beginLoading(.immediate)
            Task {
                do {
                    defer { endLoading(.immediate) }
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
                    let todosWithDueDate = try await todosWithDueDatePage.items.map { TodayTodoItem(from: $0) }
                    let todosWithoutDueDate = try await todosWithoutDueDatePage.items.map { TodayTodoItem(from: $0) }
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
                    send(.updateTodo(TodayTodoItem(from: todo)))
                } catch {
                    send(.setAlert(true))
                }
            }
        }
    }
}

private extension TodayViewModel {
    func reduceByUser(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .refresh:
            return [.fetchTodos]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .setSummaryScope(let scope):
            if state.selectedSummaryScope == scope, scope != .all {
                state.selectedSummaryScope = .all
            } else {
                state.selectedSummaryScope = scope
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
        case .onAppear:
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
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
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
    ) -> SectionBuckets {
        let startOfToday = calendar.startOfDay(for: Date())
        guard let windowEnd = calendar.date(byAdding: .day, value: upcomingWindowDays, to: startOfToday) else {
            return SectionBuckets(
                focused: items.filter(\.isPinned),
                unscheduled: items.filter { !$0.isPinned && $0.dueDate == nil }
            )
        }

        var buckets = SectionBuckets()

        for item in items {
            if item.isPinned {
                buckets.focused.append(item)
                continue
            }

            guard let dueDate = item.dueDate else {
                buckets.unscheduled.append(item)
                continue
            }

            let dueDay = calendar.startOfDay(for: dueDate)
            if dueDay < startOfToday {
                buckets.overdue.append(item)
            } else if dueDay <= windowEnd {
                buckets.dueSoon.append(item)
            } else {
                buckets.later.append(item)
            }
        }

        return buckets
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
