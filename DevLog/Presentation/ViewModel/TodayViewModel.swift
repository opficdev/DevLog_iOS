//
//  TodayViewModel.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation

@Observable
final class TodayViewModel: Store {
    typealias SectionContent = (title: String, items: [TodayTodoItem])
    
    enum SummaryScope: Hashable, CaseIterable {
        case all
        case focused
        case overdue
        case dueSoon
    }

    struct State: Equatable {
        var todos: [TodayTodoItem] = []
        var isLoading: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var selectedSummaryScope: SummaryScope = .all
    }

    enum Action {
        case refresh
        case setAlert(Bool)
        case setSummaryScope(SummaryScope)
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
    private let fetchTodoByIDUseCase: FetchTodoByIDUseCase
    private let upsertTodoUseCase: UpsertTodoUseCase

    init(
        fetchTodosUseCase: FetchTodosUseCase,
        fetchTodoByIDUseCase: FetchTodoByIDUseCase,
        upsertTodoUseCase: UpsertTodoUseCase
    ) {
        self.fetchTodosUseCase = fetchTodosUseCase
        self.fetchTodoByIDUseCase = fetchTodoByIDUseCase
        self.upsertTodoUseCase = upsertTodoUseCase
    }

    var remainingCount: Int { state.todos.count }

    var focusedCount: Int {
        state.todos.filter(\.isPinned).count
    }

    var overdueCount: Int {
        state.todos.filter(isOverdue).count
    }

    var dueSoonCount: Int {
        state.todos.filter(isDueSoon).count
    }

    var selectedSummaryScope: SummaryScope {
        state.selectedSummaryScope
    }

    func summaryValue(for scope: SummaryScope) -> Int {
        switch scope {
        case .all:
            return remainingCount
        case .focused:
            return focusedCount
        case .overdue:
            return overdueCount
        case .dueSoon:
            return dueSoonCount
        }
    }

    var emptyStateTitle: String {
        switch state.selectedSummaryScope {
        case .all:
            return "남아 있는 Todo가 없습니다."
        case .focused:
            return "집중할 일이 없습니다."
        case .overdue:
            return "지난 마감 Todo가 없습니다."
        case .dueSoon:
            return "\(upcomingWindowDays)일 내 일정이 없습니다."
        }
    }

    var emptyStateMessage: String {
        switch state.selectedSummaryScope {
        case .all:
            return "완료되지 않은 일이 생기면 이곳에서 우선순위대로 볼 수 있습니다."
        case .focused:
            return "중요 표시한 Todo가 생기면 이곳에서 바로 볼 수 있습니다."
        case .overdue:
            return "지금은 기한이 지난 Todo가 없습니다."
        case .dueSoon:
            return "곧 마감되는 Todo가 생기면 이곳에서 먼저 볼 수 있습니다."
        }
    }

    var sections: [SectionContent] {
        let allSections: [SectionContent] = [
            ("집중할 일", state.todos.filter(\.isPinned)),
            ("지난 마감", state.todos.filter { !$0.isPinned && isOverdue($0) }),
            ("\(upcomingWindowDays)일 내 일정", state.todos.filter { !$0.isPinned && isDueSoon($0) }),
            ("나중 일정", state.todos.filter { !$0.isPinned && isScheduledLater($0) }),
            ("일정 미정", state.todos.filter { !$0.isPinned && $0.dueDate == nil })
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

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .refresh, .setAlert, .setSummaryScope, .completeTodo, .togglePinned:
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
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
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
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    var todo = try await fetchTodoByIDUseCase.execute(item.id)
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
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    var todo = try await fetchTodoByIDUseCase.execute(item.id)
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
        case .removeTodo(let todoID):
            state.todos.removeAll { $0.id == todoID }
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

    func isOverdue(_ item: TodayTodoItem) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: Date())
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

    func isScheduledLater(_ item: TodayTodoItem) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        let startOfToday = calendar.startOfDay(for: Date())
        guard let windowEnd = calendar.date(byAdding: .day, value: upcomingWindowDays, to: startOfToday) else {
            return false
        }
        let dueDay = calendar.startOfDay(for: dueDate)
        return windowEnd < dueDay
    }
}
