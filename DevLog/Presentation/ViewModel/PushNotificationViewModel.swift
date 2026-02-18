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
        var pendingTask: (PushNotification, Int)?
        var sortOption: SortOption
        var timeFilter: TimeFilter
        var showUnreadOnly: Bool
        var selectedTodoID: TodoIDItem?
    }

    enum Action {
        case fetchNotifications
        case deleteNotification(PushNotification)
        case toggleRead(PushNotification)
        case undoDelete
        case confirmDelete
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case setLoading(Bool)
        case setNotifications([PushNotification])
        case toggleSortOption
        case setTimeFilter(TimeFilter)
        case toggleUnreadOnly
        case resetFilters
        case tapNotification(PushNotification)
        case setSelectedTodoID(TodoIDItem?)
    }

    enum SideEffect {
        case fetchNotifications
        case delete(PushNotification)
        case toggleRead(String)
    }

    enum AlertType {
        case error
    }

    enum ToastType {
        case delete
    }

    enum SortOption: CaseIterable {
        case latest
        case oldest

        var title: String {
            switch self {
            case .latest: return "최신순"
            case .oldest: return "예전순"
            }
        }
    }

    enum TimeFilter: Equatable {
        case none
        case hours(Int)
        case days(Int)

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

        static var availableOptions: [TimeFilter] {[
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

    @Published private(set) var state: State
    private let fetchNotificationUseCase: FetchPushNotificationsUseCase
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
        self.fetchNotificationUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
        self.toggleReadUseCase = toggleReadUseCase
        self.userDefaults = userDefaults
        self.state = State(
            sortOption: Self.loadSortOption(userDefaults: userDefaults),
            timeFilter: Self.loadTimeFilter(userDefaults: userDefaults),
            showUnreadOnly: userDefaults.bool(forKey: DefaultsKey.showUnreadOnly)
        )
    }

    var displayedNotifications: [PushNotification] {
        var items = state.notifications

        if state.showUnreadOnly {
            items = items.filter { $0.isRead == false }
        }

        if case let .hours(value) = state.timeFilter {
            let threshold = Date().addingTimeInterval(-Double(value) * 3600.0)
            items = items.filter { $0.receivedAt >= threshold }
        } else if case let .days(value) = state.timeFilter {
            let threshold = Date().addingTimeInterval(-Double(value) * 86400.0)
            items = items.filter { $0.receivedAt >= threshold }
        }

        switch state.sortOption {
        case .latest:
            return items.sorted { $0.receivedAt > $1.receivedAt }
        case .oldest:
            return items.sorted { $0.receivedAt < $1.receivedAt }
        }
    }

    var appliedFilterCount: Int {
        var count = 0
        if state.sortOption != .latest { count += 1 }
        if state.timeFilter != .none { count += 1 }
        if state.showUnreadOnly { count += 1 }
        return count
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .deleteNotification, .toggleRead, .undoDelete, .setAlert, .toggleSortOption,
                .setTimeFilter, .toggleUnreadOnly, .resetFilters, .tapNotification:
            effects = reduceByUser(action, state: &state)

        case .fetchNotifications, .confirmDelete, .setToast, .setSelectedTodoID:
            effects = reduceByView(action, state: &state)

        case .setLoading, .setNotifications:
            effects = reduceByRun(action, state: &state)
        }

        self.state = state
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchNotifications:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let notifications = try await fetchNotificationUseCase.execute()
                    send(.setNotifications(notifications))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .delete(let notification):
            Task {
                do {
                    try await deleteUseCase.execute(notification.id)
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .toggleRead(let todoID):
            Task {
                do {
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
            state.sortOption = state.sortOption == .latest ? .oldest : .latest
            saveSortOption(state.sortOption)
        case .setTimeFilter(let filter):
            state.timeFilter = filter
            saveTimeFilter(filter)
        case .toggleUnreadOnly:
            state.showUnreadOnly.toggle()
            userDefaults.set(state.showUnreadOnly, forKey: DefaultsKey.showUnreadOnly)
        case .resetFilters:
            state.sortOption = .latest
            state.timeFilter = .none
            state.showUnreadOnly = false
            saveSortOption(.latest)
            saveTimeFilter(.none)
            userDefaults.set(false, forKey: DefaultsKey.showUnreadOnly)
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
            return [.fetchNotifications]
        case .confirmDelete:
            guard let (item, _ ) = state.pendingTask else { return [] }
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
        case .setNotifications(let notifications):
            state.notifications = notifications
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

    static func loadSortOption(userDefaults: UserDefaults) -> SortOption {
        guard let rawValue = userDefaults.string(forKey: DefaultsKey.sortOption) else {
            return .latest
        }
        return rawValue == "oldest" ? .oldest : .latest
    }

    static func loadTimeFilter(userDefaults: UserDefaults) -> TimeFilter {
        let id = userDefaults.string(forKey: DefaultsKey.timeFilter) ?? "none"
        return TimeFilter(id: id)
    }

    func saveSortOption(_ option: SortOption) {
        let value = option == .oldest ? "oldest" : "latest"
        userDefaults.set(value, forKey: DefaultsKey.sortOption)
    }

    func saveTimeFilter(_ filter: TimeFilter) {
        userDefaults.set(filter.id, forKey: DefaultsKey.timeFilter)
    }
}
