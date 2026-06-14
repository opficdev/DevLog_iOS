//
//  PushNotificationListFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/12/26.
//

import Combine
import ComposableArchitecture
import DevLogCore
import DevLogDomain
import Foundation

@Reducer
struct PushNotificationListFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        @Presents var sheet: SheetState?
        var notifications: [PushNotificationItem] = []
        var hasMore = false
        var nextCursor: PushNotificationCursor?
        var query: PushNotificationQuery
        var selectedNotificationId: String?
        var selectedTodoId: TodoIdItem?
        var loading = LoadingFeature.State()
        var undoNotificationId: String?

        init(query: PushNotificationQuery = .default) {
            self.query = query
        }

        var isLoading: Bool {
            loading.isLoading
        }

        var appliedFilterCount: Int {
            var count = 0
            if query.sortOrder != .latest { count += 1 }
            if query.timeFilter != .none { count += 1 }
            if query.unreadOnly { count += 1 }
            return count
        }
    }

    @ObservableState
    struct SheetState: Equatable, Identifiable {
        let todoId: String
        var id: String { todoId }
    }

    enum Action: BindableAction {
        case alert(PresentationAction<Never>)
        case sheet(PresentationAction<Sheet>)
        case binding(BindingAction<State>)
        case fetchNotifications
        case loadNextPage
        case deleteNotification(PushNotificationItem)
        case toggleRead(PushNotificationItem)
        case undoDelete
        case finishDeleteToast(String)
        case toggleSortOption
        case toggleUnreadOnly
        case resetFilters
        case selectNotification(String?)
        case syncSheetPresentation(isCompactLayout: Bool)
        case store(StoreAction)
        case loading(LoadingFeature.Action)

        enum Sheet: Equatable {
            case tapCloseButton
        }

        enum StoreAction: Equatable {
            case setAlert
            case appendNotifications([PushNotificationItem], nextCursor: PushNotificationCursor?)
            case resetPagination
            case setHasMore(Bool)
            case syncNotifications([PushNotificationItem], nextCursor: PushNotificationCursor?, hasMore: Bool)
            case setNotificationHidden(String, Bool)
            case setNotificationRead(String, Bool)
            case observeNotifications(PushNotificationQuery, Int)
        }
    }

    enum CancelID: Hashable {
        case fetchNotifications
        case observeNotifications
        case toggleRead
    }

    @Dependency(\.fetchPushNotificationsUseCase) var fetchPushNotificationsUseCase
    @Dependency(\.deletePushNotificationUseCase) var deletePushNotificationUseCase
    @Dependency(\.undoDeletePushNotificationUseCase) var undoDeletePushNotificationUseCase
    @Dependency(\.togglePushNotificationReadUseCase) var togglePushNotificationReadUseCase
    @Dependency(\.updatePushNotificationQueryUseCase) var updatePushNotificationQueryUseCase

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        BindingReducer()
        Reduce { state, action in
            reduce(action, state: &state)
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$sheet, action: \.sheet) {
            PushNotificationListSheetFeature()
        }
    }
}

private struct PushNotificationListSheetFeature: Reducer {
    typealias State = PushNotificationListFeature.SheetState
    typealias Action = PushNotificationListFeature.Action.Sheet

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

private extension PushNotificationListFeature {
    func reduce(
        _ action: Action,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .alert:
            break
        case .sheet(.dismiss), .sheet(.presented(.tapCloseButton)):
            state.sheet = nil
            state.selectedNotificationId = nil
            state.selectedTodoId = nil
        case .sheet:
            break
        case .binding(\.query.timeFilter):
            state.nextCursor = nil
            return refreshForQueryChangeEffect(query: state.query)
        case .binding:
            break
        case .fetchNotifications:
            state.nextCursor = nil
            return fetchNotificationsEffect(query: state.query, cursor: nil, existingCount: 0)
        case .loadNextPage:
            guard state.hasMore, !state.isLoading else { return .none }
            return fetchNotificationsEffect(
                query: state.query,
                cursor: state.nextCursor,
                existingCount: state.notifications.count
            )
        case .deleteNotification(let item):
            guard state.notifications.contains(where: { $0.id == item.id }) else { return .none }
            state.undoNotificationId = item.id
            Self.setNotificationHidden(&state, notificationId: item.id, isHidden: true)
            return deleteNotificationEffect(item)
        case .toggleRead(let item):
            guard let index = state.notifications.firstIndex(where: { $0.id == item.id }) else {
                return .none
            }
            let isRead = !state.notifications[index].isRead
            state.notifications[index].isRead = isRead
            return toggleReadEffect(notificationId: item.id, todoId: item.todoId, rollbackRead: !isRead)
        case .undoDelete:
            guard let undoNotificationId = state.undoNotificationId else { return .none }
            Self.setNotificationHidden(&state, notificationId: undoNotificationId, isHidden: false)
            state.undoNotificationId = nil
            return undoDeleteEffect(undoNotificationId)
        case .finishDeleteToast(let notificationId):
            state.notifications.removeAll { $0.id == notificationId && $0.isHidden }
            if state.undoNotificationId == notificationId {
                state.undoNotificationId = nil
            }
        case .store(.setAlert):
            state.alert = Self.alertState()
        case .store(.appendNotifications(let notifications, let nextCursor)):
            state.notifications.append(contentsOf: Self.mergedHiddenNotifications(
                currentNotifications: state.notifications,
                incomingNotifications: notifications
            ))
            state.nextCursor = nextCursor
        case .store(.resetPagination):
            state.notifications = []
            state.nextCursor = nil
        case .store(.setHasMore(let value)):
            state.hasMore = value
        case .store(.syncNotifications(let notifications, let nextCursor, let hasMore)):
            state.notifications = Self.mergedHiddenNotifications(
                currentNotifications: state.notifications,
                incomingNotifications: notifications
            )
            state.nextCursor = nextCursor
            state.hasMore = hasMore
        case .store(.setNotificationHidden(let notificationId, let isHidden)):
            Self.setNotificationHidden(&state, notificationId: notificationId, isHidden: isHidden)
        case .store(.setNotificationRead(let notificationId, let isRead)):
            if let index = state.notifications.firstIndex(where: { $0.id == notificationId }) {
                state.notifications[index].isRead = isRead
            }
        case .toggleSortOption:
            state.query.sortOrder = state.query.sortOrder == .latest ? .oldest : .latest
            state.nextCursor = nil
            return refreshForQueryChangeEffect(query: state.query)
        case .toggleUnreadOnly:
            state.query.unreadOnly.toggle()
            state.nextCursor = nil
            return refreshForQueryChangeEffect(query: state.query)
        case .resetFilters:
            state.query = .default
            state.nextCursor = nil
            return refreshForQueryChangeEffect(query: state.query)
        case .selectNotification(let notificationId):
            state.selectedNotificationId = notificationId
            guard let notificationId else {
                state.selectedTodoId = nil
                return .none
            }
            guard let index = state.notifications.firstIndex(where: { $0.id == notificationId }) else {
                state.selectedTodoId = nil
                return .none
            }
            let item = state.notifications[index]
            state.selectedTodoId = TodoIdItem(id: item.todoId)
            guard !item.isRead else { return .none }
            state.notifications[index].isRead = true
            return toggleReadEffect(notificationId: item.id, todoId: item.todoId, rollbackRead: false)
        case .syncSheetPresentation(let isCompactLayout):
            if let todoId = state.selectedTodoId?.id, isCompactLayout {
                state.sheet = .init(todoId: todoId)
            } else {
                state.sheet = nil
            }
        case .store(.observeNotifications(let query, let limit)):
            return observeNotificationsEffect(query: query, limit: limit)
        case .loading:
            break
        }

        return .none
    }

    func refreshForQueryChangeEffect(query: PushNotificationQuery) -> Effect<Action> {
        .merge(
            updateQueryEffect(query: query),
            fetchNotificationsEffect(query: query, cursor: nil, existingCount: 0)
        )
    }

    func fetchNotificationsEffect(
        query: PushNotificationQuery,
        cursor: PushNotificationCursor?,
        existingCount: Int
    ) -> Effect<Action> {
        let limit = max(query.pageSize, existingCount)
        let fetchEffect: Effect<Action> = .run { [fetchPushNotificationsUseCase] send in
            await send(.loading(.begin(target: .default, mode: .delayed)))
            do {
                let page = try await fetchPushNotificationsUseCase.execute(query, cursor: cursor)
                if cursor == nil {
                    await send(.store(.resetPagination))
                }
                await send(
                    .store(.appendNotifications(
                        page.items.map(PushNotificationItem.init(from:)),
                        nextCursor: page.nextCursor
                    ))
                )
                await send(.store(.setHasMore(page.items.count == query.pageSize && page.nextCursor != nil)))
                await send(.store(.observeNotifications(query, max(limit, existingCount + page.items.count))))
                await send(.loading(.end(target: .default, mode: .delayed)))
            } catch {
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.store(.setAlert))
            }
        }
        .cancellable(id: CancelID.fetchNotifications, cancelInFlight: true)

        if cursor == nil {
            return .concatenate(
                .cancel(id: CancelID.observeNotifications),
                fetchEffect
            )
        }

        return fetchEffect
    }

    func observeNotificationsEffect(
        query: PushNotificationQuery,
        limit: Int
    ) -> Effect<Action> {
        .run { [fetchPushNotificationsUseCase] send in
            do {
                let publisher = try fetchPushNotificationsUseCase.observe(query, limit: limit)
                for try await page in publisher.values {
                    let items = page.items.map(PushNotificationItem.init(from:))
                    let hasMore = items.count == max(query.pageSize, limit) && page.nextCursor != nil
                    await send(.store(.syncNotifications(items, nextCursor: page.nextCursor, hasMore: hasMore)))
                }
            } catch is CancellationError {
            } catch {
                await send(.store(.setAlert))
            }
        }
        .cancellable(id: CancelID.observeNotifications, cancelInFlight: true)
    }

    func deleteNotificationEffect(_ item: PushNotificationItem) -> Effect<Action> {
        .run { [deletePushNotificationUseCase] send in
            do {
                try await deletePushNotificationUseCase.execute(item.id)
            } catch {
                await send(.store(.setNotificationHidden(item.id, false)))
                await send(.store(.setAlert))
            }
        }
    }

    func undoDeleteEffect(_ notificationId: String) -> Effect<Action> {
        .run { [undoDeletePushNotificationUseCase] send in
            do {
                try await undoDeletePushNotificationUseCase.execute(notificationId)
            } catch {
                await send(.store(.setNotificationHidden(notificationId, true)))
                await send(.store(.setAlert))
            }
        }
    }

    func toggleReadEffect(
        notificationId: String,
        todoId: String,
        rollbackRead: Bool
    ) -> Effect<Action> {
        .run { [togglePushNotificationReadUseCase] send in
            await send(.loading(.begin(target: .default, mode: .delayed)))
            do {
                try await togglePushNotificationReadUseCase.execute(todoId)
                await send(.loading(.end(target: .default, mode: .delayed)))
            } catch {
                await send(.store(.setNotificationRead(notificationId, rollbackRead)))
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.store(.setAlert))
            }
        }
        .cancellable(id: CancelID.toggleRead, cancelInFlight: true)
    }

    func updateQueryEffect(query: PushNotificationQuery) -> Effect<Action> {
        .run { [updatePushNotificationQueryUseCase] _ in
            updatePushNotificationQueryUseCase.execute(query)
        }
    }

    static func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close"))
            }
        } message: {
            TextState(String(localized: "common_error_message"))
        }
    }

    static func setNotificationHidden(
        _ state: inout State,
        notificationId: String,
        isHidden: Bool
    ) {
        if let index = state.notifications.firstIndex(where: { $0.id == notificationId }) {
            state.notifications[index].isHidden = isHidden
        }
    }

    static func mergedHiddenNotifications(
        currentNotifications: [PushNotificationItem],
        incomingNotifications: [PushNotificationItem]
    ) -> [PushNotificationItem] {
        let hiddenNotificationIds = Set(currentNotifications.filter(\.isHidden).map(\.id))

        return incomingNotifications.map { notification in
            guard hiddenNotificationIds.contains(notification.id) else {
                return notification
            }

            var hiddenNotification = notification
            hiddenNotification.isHidden = true
            return hiddenNotification
        }
    }
}
