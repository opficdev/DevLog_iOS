//
//  PushNotificationListViewModelTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/6/26.
//

import Testing
import Foundation
@testable import DevLog

@MainActor
struct DeletePushNotificationTests {
    @Test("삭제하면 항목이 즉시 사라지고 되돌리기 토스트가 표시되며 삭제 유스케이스가 호출된다")
    func 삭제하면_항목이_즉시_사라지고_되돌리기_토스트가_표시되며_삭제_유스케이스가_호출된다() async throws {
        let fetchPushNotificationsUseCaseSpy = FetchPushNotificationsUseCaseSpy(
            pushNotificationPage: PushNotificationPage(
                items: [
                    PushNotification(
                        id: "notification-1",
                        title: "title",
                        body: "body",
                        receivedAt: .now,
                        isRead: false,
                        todoId: "todo-1",
                        todoCategory: .system(.feature)
                    )
                ],
                nextCursor: nil
            )
        )
        let deletePushNotificationUseCaseSpy = DeletePushNotificationUseCaseSpy()
        let undoDeletePushNotificationUseCaseSpy = UndoDeletePushNotificationUseCaseSpy()
        let togglePushNotificationReadUseCaseSpy = TogglePushNotificationReadUseCaseSpy()
        let fetchPushNotificationQueryUseCaseSpy = FetchPushNotificationQueryUseCaseSpy()
        let updatePushNotificationQueryUseCaseSpy = UpdatePushNotificationQueryUseCaseSpy()

        let pushNotificationListViewModel = PushNotificationListViewModel(
            fetchUseCase: fetchPushNotificationsUseCaseSpy,
            deleteUseCase: deletePushNotificationUseCaseSpy,
            undoDeleteUseCase: undoDeletePushNotificationUseCaseSpy,
            toggleReadUseCase: togglePushNotificationReadUseCaseSpy,
            fetchQueryUseCase: fetchPushNotificationQueryUseCaseSpy,
            updateQueryUseCase: updatePushNotificationQueryUseCaseSpy
        )

        pushNotificationListViewModel.send(.fetchNotifications)
        await waitUntil {
            !pushNotificationListViewModel.state.notifications.isEmpty
        }

        let pushNotificationItem = try #require(pushNotificationListViewModel.state.notifications.first)

        pushNotificationListViewModel.send(.deleteNotification(pushNotificationItem))

        #expect(pushNotificationListViewModel.state.notifications.isEmpty)
        #expect(pushNotificationListViewModel.state.showToast)

        await waitUntil {
            deletePushNotificationUseCaseSpy.calledNotificationIds == ["notification-1"]
        }

        #expect(deletePushNotificationUseCaseSpy.calledNotificationIds == ["notification-1"])
    }

    @Test("삭제를 되돌리면 되돌리기 유스케이스가 호출되고 다시 조회한다")
    func 삭제를_되돌리면_되돌리기_유스케이스가_호출되고_다시_조회한다() async throws {
        let fetchPushNotificationsUseCaseSpy = FetchPushNotificationsUseCaseSpy(
            pushNotificationPage: PushNotificationPage(
                items: [
                    PushNotification(
                        id: "notification-1",
                        title: "title",
                        body: "body",
                        receivedAt: .now,
                        isRead: false,
                        todoId: "todo-1",
                        todoCategory: .system(.feature)
                    )
                ],
                nextCursor: nil
            )
        )
        let deletePushNotificationUseCaseSpy = DeletePushNotificationUseCaseSpy()
        let undoDeletePushNotificationUseCaseSpy = UndoDeletePushNotificationUseCaseSpy()
        let togglePushNotificationReadUseCaseSpy = TogglePushNotificationReadUseCaseSpy()
        let fetchPushNotificationQueryUseCaseSpy = FetchPushNotificationQueryUseCaseSpy()
        let updatePushNotificationQueryUseCaseSpy = UpdatePushNotificationQueryUseCaseSpy()

        let pushNotificationListViewModel = PushNotificationListViewModel(
            fetchUseCase: fetchPushNotificationsUseCaseSpy,
            deleteUseCase: deletePushNotificationUseCaseSpy,
            undoDeleteUseCase: undoDeletePushNotificationUseCaseSpy,
            toggleReadUseCase: togglePushNotificationReadUseCaseSpy,
            fetchQueryUseCase: fetchPushNotificationQueryUseCaseSpy,
            updateQueryUseCase: updatePushNotificationQueryUseCaseSpy
        )

        pushNotificationListViewModel.send(.fetchNotifications)
        await waitUntil {
            !pushNotificationListViewModel.state.notifications.isEmpty
        }

        let pushNotificationItem = try #require(pushNotificationListViewModel.state.notifications.first)

        pushNotificationListViewModel.send(.deleteNotification(pushNotificationItem))
        pushNotificationListViewModel.send(.undoDelete)

        await waitUntil {
            undoDeletePushNotificationUseCaseSpy.calledNotificationIds == ["notification-1"]
        }

        #expect(undoDeletePushNotificationUseCaseSpy.calledNotificationIds == ["notification-1"])
        #expect(2 <= fetchPushNotificationsUseCaseSpy.executeCallCount)
    }
}
