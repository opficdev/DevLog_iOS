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
        case restoreNotification(PushNotificationItem, Int)
        case toggleSortOption
        case setTimeFilter(PushNotificationQuery.TimeFilter)
        case toggleUnreadOnly
        case resetFilters
        case tapNotification(PushNotificationItem)
        case setSelectedTodoId(TodoIdItem?)
    }

    enum SideEffect {
        case fetchNotifications(PushNotificationQuery, cursor: PushNotificationCursor?)
        case delete(PushNotificationItem, Int)
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
                .syncNotifications, .restoreNotification:
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
            beginLoading(.immediate)
            Task {
                do {
                    defer { endLoading(.immediate) }
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
        case .delete(let item, let index):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    try await deleteUseCase.execute(item.id)
                } catch {
                    send(.restoreNotification(item, index))
                    send(.setAlert(isPresented: true))
                }
            }
        case .undoDelete(let notificationId):
            beginLoading(.delayed)
            Task {
                // endLoading(.delayed)를 defer로 두지 않는 이유
                // send(.fetchNotifications)가 같은 턴에서 beginLoading(.immediate)를 먼저 올린 뒤
                // delayed 로딩을 내려야 같은 isLoading이 끊기지 않기 때문
                do {
                    try await undoDeleteUseCase.execute(notificationId)
                } catch {
                    send(.setAlert(isPresented: true))
                }

                send(.fetchNotifications)
                endLoading(.delayed)
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
            if let index = state.notifications.firstIndex(where: { $0.id == item.id }) {
                undoDeleteNotificationId = item.id
                state.notifications.remove(at: index)
                setToast(&state, isPresented: true)
                return [.delete(item, index)]
            }
            return []
        case .toggleRead(let item):
            if let index = state.notifications.firstIndex(where: { $0.id == item.id }) {
                state.notifications[index].isRead.toggle()
                return [.toggleRead(item.todoId)]
            }
        case .undoDelete:
            guard let undoDeleteNotificationId else { return [] }
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
                undoDeleteNotificationId = nil
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
            state.notifications.append(contentsOf: notifications)
            state.nextCursor = nextCursor
        case .syncNotifications(let notifications, let nextCursor, let hasMore):
            state.notifications = notifications
            state.nextCursor = nextCursor
            state.hasMore = hasMore
        case .restoreNotification(let notification, let index):
            if state.notifications.contains(where: { $0.id == notification.id }) { break }

            if index <= state.notifications.count {
                state.notifications.insert(notification, at: index)
            } else {
                state.notifications.append(notification)
            }

            if undoDeleteNotificationId == notification.id {
                undoDeleteNotificationId = nil
            }
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
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }

    func setToast(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.toastMessage = "실행 취소"
        state.showToast = isPresented
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
