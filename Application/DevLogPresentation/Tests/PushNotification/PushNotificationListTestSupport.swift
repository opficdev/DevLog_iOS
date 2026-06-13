//
//  PushNotificationListTestSupport.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/12/26.
//

import Testing
import Combine
import ComposableArchitecture
import DevLogCore
import DevLogDomain
import Foundation
@testable import DevLogPresentation

@MainActor
protocol PushNotificationListStateDriving {
    var notifications: [PushNotificationItem] { get }
    var query: PushNotificationQuery { get }
    var hasMore: Bool { get }
    var selectedNotificationId: String? { get }
    var selectedTodoId: TodoIdItem? { get }
    var appliedFilterCount: Int { get }

    func fetchNotifications() async
    func loadNextPage() async
    func toggleSortOption() async
    func setTimeFilter(_ filter: PushNotificationQuery.TimeFilter) async
    func toggleUnreadOnly() async
    func resetFilters() async
    func selectNotification(_ notificationId: String?) async
    func toggleRead(_ item: PushNotificationItem) async
    func deleteNotification(_ item: PushNotificationItem) async
    func undoDelete() async
    func finishDeleteToast(_ notificationId: String) async
}

@MainActor
struct PushNotificationListViewModelTestAdapter: PushNotificationListStateDriving {
    private let viewModel: PushNotificationListViewModel

    var notifications: [PushNotificationItem] { viewModel.state.notifications }
    var query: PushNotificationQuery { viewModel.state.query }
    var hasMore: Bool { viewModel.state.hasMore }
    var selectedNotificationId: String? { viewModel.state.selectedNotificationId }
    var selectedTodoId: TodoIdItem? { viewModel.state.selectedTodoId }
    var appliedFilterCount: Int { viewModel.appliedFilterCount }

    init(
        fetchUseCase: FetchPushNotificationsUseCase = PushNotificationListFetchUseCaseSpy(),
        deleteUseCase: DeletePushNotificationUseCase = DeletePushNotificationUseCaseSpy(),
        undoDeleteUseCase: UndoDeletePushNotificationUseCase = UndoDeletePushNotificationUseCaseSpy(),
        toggleReadUseCase: TogglePushNotificationReadUseCase = TogglePushNotificationReadUseCaseSpy(),
        fetchQueryUseCase: FetchPushNotificationQueryUseCase = FetchPushNotificationQueryUseCaseSpy(),
        updateQueryUseCase: UpdatePushNotificationQueryUseCase = UpdatePushNotificationQueryUseCaseSpy()
    ) {
        viewModel = PushNotificationListViewModel(
            fetchUseCase: fetchUseCase,
            deleteUseCase: deleteUseCase,
            undoDeleteUseCase: undoDeleteUseCase,
            toggleReadUseCase: toggleReadUseCase,
            fetchQueryUseCase: fetchQueryUseCase,
            updateQueryUseCase: updateQueryUseCase
        )
    }

    func fetchNotifications() async {
        viewModel.send(.fetchNotifications)
    }

    func loadNextPage() async {
        viewModel.send(.loadNextPage)
    }

    func toggleSortOption() async {
        viewModel.send(.toggleSortOption)
    }

    func setTimeFilter(_ filter: PushNotificationQuery.TimeFilter) async {
        viewModel.send(.setTimeFilter(filter))
    }

    func toggleUnreadOnly() async {
        viewModel.send(.toggleUnreadOnly)
    }

    func resetFilters() async {
        viewModel.send(.resetFilters)
    }

    func selectNotification(_ notificationId: String?) async {
        viewModel.send(.selectNotification(notificationId))
    }

    func toggleRead(_ item: PushNotificationItem) async {
        viewModel.send(.toggleRead(item))
    }

    func deleteNotification(_ item: PushNotificationItem) async {
        viewModel.send(.deleteNotification(item))
    }

    func undoDelete() async {
        viewModel.send(.undoDelete)
    }

    func finishDeleteToast(_ notificationId: String) async {
        viewModel.send(.finishDeleteToast(notificationId))
    }
}

@MainActor
struct PushNotificationListStoreTestAdapter: PushNotificationListStateDriving {
    private let store: TestStoreOf<PushNotificationListFeature>

    var notifications: [PushNotificationItem] { store.state.notifications }
    var query: PushNotificationQuery { store.state.query }
    var hasMore: Bool { store.state.hasMore }
    var selectedNotificationId: String? { store.state.selectedNotificationId }
    var selectedTodoId: TodoIdItem? { store.state.selectedTodoId }
    var appliedFilterCount: Int { store.state.appliedFilterCount }

    init(
        fetchUseCase: FetchPushNotificationsUseCase = PushNotificationListFetchUseCaseSpy(),
        deleteUseCase: DeletePushNotificationUseCase = DeletePushNotificationUseCaseSpy(),
        undoDeleteUseCase: UndoDeletePushNotificationUseCase = UndoDeletePushNotificationUseCaseSpy(),
        toggleReadUseCase: TogglePushNotificationReadUseCase = TogglePushNotificationReadUseCaseSpy(),
        fetchQueryUseCase: FetchPushNotificationQueryUseCase = FetchPushNotificationQueryUseCaseSpy(),
        updateQueryUseCase: UpdatePushNotificationQueryUseCase = UpdatePushNotificationQueryUseCaseSpy(),
        configureDependencies: ((inout DependencyValues) -> Void)? = nil
    ) {
        store = TestStore(
            initialState: PushNotificationListFeature.State(
                query: fetchQueryUseCase.execute()
            )
        ) {
            PushNotificationListFeature()
        } withDependencies: {
            $0.fetchPushNotificationsUseCase = fetchUseCase
            $0.deletePushNotificationUseCase = deleteUseCase
            $0.undoDeletePushNotificationUseCase = undoDeleteUseCase
            $0.togglePushNotificationReadUseCase = toggleReadUseCase
            $0.updatePushNotificationQueryUseCase = updateQueryUseCase
            $0.continuousClock = ContinuousClock()
            configureDependencies?(&$0)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func fetchNotifications() async {
        await store.send(.fetchNotifications)
        await drainReceivedActions()
    }

    func loadNextPage() async {
        await store.send(.loadNextPage)
        await drainReceivedActions()
    }

    func toggleSortOption() async {
        await store.send(.toggleSortOption)
        await drainReceivedActions()
    }

    func setTimeFilter(_ filter: PushNotificationQuery.TimeFilter) async {
        await store.send(.setTimeFilter(filter))
        await drainReceivedActions()
    }

    func toggleUnreadOnly() async {
        await store.send(.toggleUnreadOnly)
        await drainReceivedActions()
    }

    func resetFilters() async {
        await store.send(.resetFilters)
        await drainReceivedActions()
    }

    func selectNotification(_ notificationId: String?) async {
        await store.send(.selectNotification(notificationId))
        await drainReceivedActions()
    }

    func toggleRead(_ item: PushNotificationItem) async {
        await store.send(.toggleRead(item))
        await drainReceivedActions()
    }

    func deleteNotification(_ item: PushNotificationItem) async {
        await store.send(.deleteNotification(item))
        if let notificationId = store.state.deleteToastNotificationId {
            presentDeleteNotificationToast(notificationId)
            await store.send(.presentedDeleteToast)
        }
        await drainReceivedActions()
    }

    func undoDelete() async {
        await store.send(.undoDelete)
        await drainReceivedActions()
    }

    func finishDeleteToast(_ notificationId: String) async {
        await store.send(.finishDeleteToast(notificationId))
    }

    private func presentDeleteNotificationToast(_ notificationId: String) {
        ToastPresenter.present(
            message: String(localized: "common_undo"),
            systemImage: "arrow.uturn.left",
            duration: 5,
            font: .caption,
            multilineTextAlignment: .center,
            lineLimit: 3,
            action: {
                Task { @MainActor in
                    await undoDelete()
                }
            },
            onDismiss: {
                Task { @MainActor in
                    await finishDeleteToast(notificationId)
                }
            }
        )
    }

    private func drainReceivedActions() async {
        for _ in 0..<8 {
            await store.skipReceivedActions(strict: false)
        }
    }
}

final class PushNotificationListFetchUseCaseSpy: FetchPushNotificationsUseCase {
    var pages: [PushNotificationPage]
    var error: Error?
    var observePublisher: AnyPublisher<PushNotificationPage, Error>
    private(set) var queries = [PushNotificationQuery]()
    private(set) var cursors = [PushNotificationCursor?]()

    init(
        pages: [PushNotificationPage] = [PushNotificationPage(items: [], nextCursor: nil)],
        observePublisher: AnyPublisher<PushNotificationPage, Error> = Empty().eraseToAnyPublisher()
    ) {
        self.pages = pages
        self.observePublisher = observePublisher
    }

    func execute(
        _ query: PushNotificationQuery,
        cursor: PushNotificationCursor?
    ) async throws -> PushNotificationPage {
        queries.append(query)
        cursors.append(cursor)

        if let error {
            throw error
        }

        let index = queries.count - 1
        if pages.count <= index {
            return pages.last ?? PushNotificationPage(items: [], nextCursor: nil)
        }
        return pages[index]
    }

    func observe(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPage, Error> {
        observePublisher
    }
}
