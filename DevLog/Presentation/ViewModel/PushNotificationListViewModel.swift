//
//  PushNotificationListViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation
import Combine

@Observable
final class PushNotificationListViewModel: Store {
    struct State: Equatable {
        var notifications: [PushNotificationItem] = []
        var showAlert: Bool = false
        var showToast: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var toastMessage: String = ""
        var isLoading: Bool = false
        var hasMore: Bool = false
        var nextCursor: PushNotificationCursor?
        var query: PushNotificationQuery
        var selectedTodoId: TodoIdItem?
    }

    enum Action {
        case fetchNotifications
        case loadNextPage
        case deleteNotification(PushNotificationItem)
        case toggleRead(PushNotificationItem)
        case undoDelete
        case setAlert(isPresented: Bool)
        case setToast(isPresented: Bool)
        case setLoading(Bool)
        case appendNotifications([PushNotificationItem], nextCursor: PushNotificationCursor?)
        case resetPagination
        case setHasMore(Bool)
        case syncNotifications([PushNotificationItem], nextCursor: PushNotificationCursor?, hasMore: Bool)
        case setNotificationHidden(String, Bool)
        case toggleSortOption
        case setTimeFilter(PushNotificationQuery.TimeFilter)
        case toggleUnreadOnly
        case resetFilters
        case tapNotification(PushNotificationItem)
        case setSelectedTodoId(TodoIdItem?)
    }

    enum SideEffect {
        case fetchNotifications(PushNotificationQuery, cursor: PushNotificationCursor?)
        case delete(PushNotificationItem)
        case undoDelete(String)
        case toggleRead(String)
    }

    private(set) var state: State
    private let fetchUseCase: FetchPushNotificationsUseCase
    private let deleteUseCase: DeletePushNotificationUseCase
    private let undoDeleteUseCase: UndoDeletePushNotificationUseCase
    private let toggleReadUseCase: TogglePushNotificationReadUseCase
    private let fetchQueryUseCase: FetchPushNotificationQueryUseCase
    private let updateQueryUseCase: UpdatePushNotificationQueryUseCase
    private let loadingState = LoadingState()
    private var undoDeleteNotificationId: String?
    private var cancellable: AnyCancellable?

    init(
        fetchUseCase: FetchPushNotificationsUseCase,
        deleteUseCase: DeletePushNotificationUseCase,
        undoDeleteUseCase: UndoDeletePushNotificationUseCase,
        toggleReadUseCase: TogglePushNotificationReadUseCase,
        fetchQueryUseCase: FetchPushNotificationQueryUseCase,
        updateQueryUseCase: UpdatePushNotificationQueryUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
        self.undoDeleteUseCase = undoDeleteUseCase
        self.toggleReadUseCase = toggleReadUseCase
        self.fetchQueryUseCase = fetchQueryUseCase
        self.updateQueryUseCase = updateQueryUseCase
        self.state = State(
            query: fetchQueryUseCase.execute()
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

        case .fetchNotifications, .setToast, .setSelectedTodoId, .loadNextPage:
            effects = reduceByView(action, state: &state)

        case .setLoading, .appendNotifications, .resetPagination, .setHasMore,
                .syncNotifications, .setNotificationHidden:
            effects = reduceByRun(action, state: &state)
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchNotifications(let query, let cursor):
            if cursor == nil {
                stopObservingNotifications()
            }
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    let existingCount = cursor == nil ? 0 : self.state.notifications.count

                    let page = try await fetchUseCase.execute(query, cursor: cursor)

                    if cursor == nil { send(.resetPagination) }
                    send(
                        .appendNotifications(
                            page.items.map { PushNotificationItem(from: $0) },
                            nextCursor: page.nextCursor
                        )
                    )

                    let hasMore = page.items.count == query.pageSize && page.nextCursor != nil
                    send(.setHasMore(hasMore))
                    startObservingNotifications(
                        query: query,
                        limit: max(query.pageSize, existingCount + page.items.count)
                    )
                } catch {
                    send(.setAlert(isPresented: true))
                }

            }
        case .delete(let item):
            Task {
                do {
                    try await deleteUseCase.execute(item.id)
                } catch {
                    send(.setNotificationHidden(item.id, false))
                    send(.setAlert(isPresented: true))
                }
            }
        case .undoDelete(let notificationId):
            Task {
                do {
                    try await undoDeleteUseCase.execute(notificationId)
                } catch {
                    send(.setNotificationHidden(notificationId, true))
                    send(.setAlert(isPresented: true))
                }
            }
        case .toggleRead(let todoId):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    try await toggleReadUseCase.execute(todoId)
                } catch {
                    send(.setAlert(isPresented: true))
                }
            }
        }
    }
}

// MARK: - Reduce Methods
private extension PushNotificationListViewModel {
    func reduceByUser(_ action: Action, state: inout State) -> [SideEffect] {
        switch action {
        case .deleteNotification(let item):
            if state.notifications.contains(where: { $0.id == item.id }) {
                undoDeleteNotificationId = item.id
                setNotificationHidden(&state, notificationId: item.id, isHidden: true)
                setToast(&state, isPresented: true)
                return [.delete(item)]
            }
            return []
        case .toggleRead(let item):
            if let index = state.notifications.firstIndex(where: { $0.id == item.id }) {
                state.notifications[index].isRead.toggle()
                return [.toggleRead(item.todoId)]
            }
        case .undoDelete:
            guard let undoDeleteNotificationId else { return [] }
            setNotificationHidden(&state, notificationId: undoDeleteNotificationId, isHidden: false)
            self.undoDeleteNotificationId = nil
            return [.undoDelete(undoDeleteNotificationId)]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .toggleSortOption:
            state.query.sortOrder = state.query.sortOrder == .latest ? .oldest : .latest
            updateQueryUseCase.execute(state.query)
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .setTimeFilter(let filter):
            state.query.timeFilter = filter
            updateQueryUseCase.execute(state.query)
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .toggleUnreadOnly:
            state.query.unreadOnly.toggle()
            updateQueryUseCase.execute(state.query)
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .resetFilters:
            state.query = .default
            updateQueryUseCase.execute(state.query)
            state.nextCursor = nil
            return [.fetchNotifications(state.query, cursor: nil)]
        case .tapNotification(let item):
            state.selectedTodoId = TodoIdItem(id: item.todoId)
            if let index = state.notifications.firstIndex(where: { $0.id == item.id }), !item.isRead {
                state.notifications[index].isRead.toggle()
                return [.toggleRead(item.todoId)]
            }
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
            guard state.hasMore, !state.isLoading else { return [] }
            return [.fetchNotifications(state.query, cursor: state.nextCursor)]
        case .setToast(let isPresented):
            setToast(&state, isPresented: isPresented)
            if !isPresented {
                if let undoDeleteNotificationId {
                    removeHiddenNotification(&state, notificationId: undoDeleteNotificationId)
                }
                self.undoDeleteNotificationId = nil
            }
        case .setSelectedTodoId(let todoId):
            state.selectedTodoId = todoId
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
            state.notifications.append(contentsOf: mergedHiddenNotifications(
                currentNotifications: state.notifications,
                incomingNotifications: notifications
            ))
            state.nextCursor = nextCursor
        case .syncNotifications(let notifications, let nextCursor, let hasMore):
            state.notifications = mergedHiddenNotifications(
                currentNotifications: state.notifications,
                incomingNotifications: notifications
            )
            state.nextCursor = nextCursor
            state.hasMore = hasMore
        case .setNotificationHidden(let notificationId, let isHidden):
            setNotificationHidden(&state, notificationId: notificationId, isHidden: isHidden)
        default:
            break
        }
        return []
    }
}

private extension PushNotificationListViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }

    func setToast(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.toastMessage = String(localized: "common_undo")
        state.showToast = isPresented
    }

    func setNotificationHidden(
        _ state: inout State,
        notificationId: String,
        isHidden: Bool
    ) {
        if let notificationIndex = state.notifications.firstIndex(where: {
            $0.id == notificationId
        }) {
            state.notifications[notificationIndex].isHidden = isHidden
        }
    }

    func removeHiddenNotification(
        _ state: inout State,
        notificationId: String
    ) {
        state.notifications.removeAll { $0.id == notificationId && $0.isHidden }
    }

    func mergedHiddenNotifications(
        currentNotifications: [PushNotificationItem],
        incomingNotifications: [PushNotificationItem]
    ) -> [PushNotificationItem] {
        incomingNotifications.map { incomingNotification in
            guard let currentNotification = currentNotifications.first(where: {
                $0.id == incomingNotification.id
            }), currentNotification.isHidden else {
                return incomingNotification
            }

            var hiddenNotification = incomingNotification
            hiddenNotification.isHidden = true
            return hiddenNotification
        }
    }

    func startObservingNotifications(
        query: PushNotificationQuery,
        limit: Int
    ) {
        cancellable = try? fetchUseCase.observe(query, limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case .failure = completion {
                        self.send(.setAlert(isPresented: true))
                    }
                },
                receiveValue: { [weak self] page in
                    guard let self else { return }
                    let items = page.items.map { PushNotificationItem(from: $0) }
                    let hasMore = items.count == max(query.pageSize, limit) && page.nextCursor != nil
                    self.send(.syncNotifications(items, nextCursor: page.nextCursor, hasMore: hasMore))
                }
            )
    }

    func stopObservingNotifications() {
        cancellable?.cancel()
        cancellable = nil
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
}

extension PushNotificationQuery.SortOrder {
    var title: String {
        switch self {
        case .latest: return String(localized: "push_sort_latest")
        case .oldest: return String(localized: "push_sort_oldest")
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
            return String(localized: "push_timefilter_all")
        case .hours(let value):
            return String.localizedStringWithFormat(
                String(localized: "push_timefilter_hours_format"),
                Int64(value)
            )
        case .days(let value):
            return String.localizedStringWithFormat(
                String(localized: "push_timefilter_days_format"),
                Int64(value)
            )
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
