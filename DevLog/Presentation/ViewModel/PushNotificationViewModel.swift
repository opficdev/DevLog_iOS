//
//  PushNotificationViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class PushNotificationViewModel: Store {
    struct State {
        var notifications: [PushNotification] = []
        var showAlert: Bool = false
        var showToast: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
        var toastMessage: String = ""
        var toastType: ToastType?
        var isLoading: Bool = false
        var hasMore: Bool = false
        var nextCursor: PushNotificationCursor?
        var pendingTask: (PushNotification, Int)?
        var query: PushNotificationQuery
        var selectedTodoID: TodoIDItem?
    }

    enum Action {
        case fetchNotifications
        case loadNextPage
        case deleteNotification(PushNotification)
        case toggleRead(PushNotification)
        case undoDelete
        case confirmDelete
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case setLoading(Bool)
        case appendNotifications([PushNotification], nextCursor: PushNotificationCursor?)
        case resetPagination
        case setHasMore(Bool)
        case toggleSortOption
        case setTimeFilter(PushNotificationQuery.TimeFilter)
        case toggleUnreadOnly
        case resetFilters
        case tapNotification(PushNotification)
        case setSelectedTodoID(TodoIDItem?)
    }

    enum SideEffect {
        case fetchNotifications(PushNotificationQuery, cursor: PushNotificationCursor?)
        case delete(PushNotification)
        case toggleRead(String)
    }

    enum AlertType {
        case error
    }

    enum ToastType {
        case delete
    }

    @Published private(set) var state: State
    private let fetchUseCase: FetchPushNotificationsUseCase
    private let deleteUseCase: DeletePushNotificationUseCase
    private let toggleReadUseCase: TogglePushNotificationReadUseCase
    private let userDefaults: UserDefaults

    private enum DefaultsKey {
        static let sortOption = "PushNotification.sortOption"
        static let timeFilter = "PushNotification.timeFilter"
        static let showUnreadOnly = "PushNotification.showUnreadOnly"
    }

    init(
        fetchUseCase: FetchPushNotificationsUseCase,
        deleteUseCase: DeletePushNotificationUseCase,
        toggleReadUseCase: TogglePushNotificationReadUseCase,
        userDefaults: UserDefaults = .standard
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
        self.toggleReadUseCase = toggleReadUseCase
        self.userDefaults = userDefaults
        self.state = State(
            query: Self.loadQuery(userDefaults: userDefaults)
        )
    }

    var appliedFilterCount: Int {
        var count = 0
        if state.query.sortOrder != .latest { count += 1 }
        if state.query.timeFilter != .none { count += 1 }
        if state.query.unreadOnly { count += 1 }
        return count
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .deleteNotification, .toggleRead, .undoDelete, .setAlert, .toggleSortOption,
                .setTimeFilter, .toggleUnreadOnly, .resetFilters, .tapNotification:
            effects = reduceByUser(action, state: &state)

        case .fetchNotifications, .confirmDelete, .setToast, .setSelectedTodoID, .loadNextPage:
            effects = reduceByView(action, state: &state)

        case .setLoading, .appendNotifications, .resetPagination, .setHasMore:
            effects = reduceByRun(action, state: &state)
        }

        self.state = state
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchNotifications(let query, let cursor):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))

                    let page = try await fetchUseCase.execute(query, cursor: cursor)

                    if cursor == nil { send(.resetPagination) }
                    send(.appendNotifications(page.items, nextCursor: page.nextCursor))

                    let hasMore = page.items.count == query.pageSize && page.nextCursor != nil
                    send(.setHasMore(hasMore))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }

            }
        case .delete(let notification):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    try await deleteUseCase.execute(notification.id)
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .toggleRead(let todoID):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    try await toggleReadUseCase.execute(todoID)
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        }
    }
}

// MARK: - Reduce Methods
private extension PushNotificationViewModel {
    func reduceByUser(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .deleteNotification(let item):
            if let index = state.notifications.firstIndex(where: { $0.id == item.id }) {
                state.pendingTask = (item, index)
                state.notifications.remove(at: index)
                setToast(&state, isPresented: true, for: .delete)
            }
        case .toggleRead(let item):
            if let index = state.notifications.firstIndex(where: { $0.id == item.id }) {
                state.notifications[index].isRead.toggle()
                return [.toggleRead(item.todoID)]
            }
        case .undoDelete:
            guard let (item, index) = state.pendingTask else { return [] }
            state.notifications.insert(item, at: index)
            state.pendingTask = nil
        case .setAlert(let isPresented, let type):
            setAlert(&state, isPresented: isPresented, for: type)
        case .toggleSortOption:
            state.query.sortOrder = state.query.sortOrder == .latest ? .oldest : .latest
            saveSortOrder(state.query.sortOrder)
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .setTimeFilter(let filter):
            state.query.timeFilter = filter
            saveTimeFilter(filter)
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .toggleUnreadOnly:
            state.query.unreadOnly.toggle()
            userDefaults.set(state.query.unreadOnly, forKey: DefaultsKey.showUnreadOnly)
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .resetFilters:
            state.query = .default
            saveSortOrder(.latest)
            saveTimeFilter(.none)
            userDefaults.set(false, forKey: DefaultsKey.showUnreadOnly)
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .tapNotification(let notification):
            state.selectedTodoID = TodoIDItem(id: notification.todoID)
        default:
            break
        }
        return []
    }

    func reduceByView(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .fetchNotifications:
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .loadNextPage:
            guard state.hasMore, !state.isLoading, state.pendingTask == nil else { return [] }
            return [.fetchNotifications(state.query, cursor: state.nextCursor)]
        case .confirmDelete:
            guard let (item, _) = state.pendingTask else { return [] }
            state.pendingTask = nil
            return [.delete(item)]
        case .setToast(let isPresented, let type):
            setToast(&state, isPresented: isPresented, for: type)
        case .setSelectedTodoID(let todoID):
            state.selectedTodoID = todoID
        default:
            break
        }
        return []
    }

    func reduceByRun(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .setLoading(let value):
            state.isLoading = value
        case .setHasMore(let value):
            state.hasMore = value
        case .resetPagination:
            state.notifications = []
            state.nextCursor = nil
        case .appendNotifications(let notifications, let nextCursor):
            let filteredNotifications: [PushNotification]
            if let (pendingItem, _) = state.pendingTask {
                filteredNotifications = notifications.filter { $0.id != pendingItem.id }
            } else {
                filteredNotifications = notifications
            }
            state.notifications.append(contentsOf: filteredNotifications)
            state.nextCursor = nextCursor
        default:
            break
        }
        return []
    }
}

private extension PushNotificationViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool,
        for type: AlertType?
    ) {
        switch type {
        case .error:
            state.alertTitle = "오류"
            state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }
        state.alertType = type
        state.showAlert = isPresented
    }

    func setToast(
        _ state: inout State,
        isPresented: Bool,
        for type: ToastType?
    ) {
        switch type {
        case .delete:
            state.toastMessage = "실행 취소"
        case .none:
            state.toastMessage = ""
        }
        state.showToast = isPresented
    }

    static func loadQuery(userDefaults: UserDefaults) -> PushNotificationQuery {
        let sortOrder = loadSortOrder(userDefaults: userDefaults)
        let timeFilter = loadTimeFilter(userDefaults: userDefaults)
        let unreadOnly = userDefaults.bool(forKey: DefaultsKey.showUnreadOnly)

        return PushNotificationQuery(
            sortOrder: sortOrder,
            timeFilter: timeFilter,
            unreadOnly: unreadOnly,
            pageSize: 20
        )
    }

    static func loadSortOrder(userDefaults: UserDefaults) -> PushNotificationQuery.SortOrder {
        guard let rawValue = userDefaults.string(forKey: DefaultsKey.sortOption) else {
            return .latest
        }
        return rawValue == "oldest" ? .oldest : .latest
    }

    static func loadTimeFilter(userDefaults: UserDefaults) -> PushNotificationQuery.TimeFilter {
        let id = userDefaults.string(forKey: DefaultsKey.timeFilter) ?? "none"
        return PushNotificationQuery.TimeFilter(id: id)
    }

    func saveSortOrder(_ order: PushNotificationQuery.SortOrder) {
        let value = order == .oldest ? "oldest" : "latest"
        userDefaults.set(value, forKey: DefaultsKey.sortOption)
    }

    func saveTimeFilter(_ filter: PushNotificationQuery.TimeFilter) {
        userDefaults.set(filter.id, forKey: DefaultsKey.timeFilter)
    }
}

extension PushNotificationQuery.SortOrder {
    var title: String {
        switch self {
        case .latest: return "최신순"
        case .oldest: return "예전순"
        }
    }
}

extension PushNotificationQuery.TimeFilter {
    var id: String {
        switch self {
        case .none: return "none"
        case .hours(let value): return "hours-\(value)"
        case .days(let value): return "days-\(value)"
        }
    }

    var title: String {
        switch self {
        case .none:
            return "전체"
        case .hours(let value):
            return "최근 \(value)시간"
        case .days(let value):
            return "최근 \(value)일"
        }
    }

    static var availableOptions: [PushNotificationQuery.TimeFilter] {[
            .none,
            .hours(1),
            .hours(6),
            .hours(24),
            .days(3),
            .days(7)
        ]
    }

    init(id: String) {
        if id == "none" {
            self = .none
        } else if id.hasPrefix("hours-") {
            let value = Int(id.replacingOccurrences(of: "hours-", with: "")) ?? 0
            self = value > 0 ? .hours(value) : .none
        } else if id.hasPrefix("days-") {
            let value = Int(id.replacingOccurrences(of: "days-", with: "")) ?? 0
            self = value > 0 ? .days(value) : .none
        } else {
            self = .none
        }
    }
}
