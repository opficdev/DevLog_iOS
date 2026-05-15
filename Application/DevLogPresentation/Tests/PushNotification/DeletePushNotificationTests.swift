//
//  DeletePushNotificationTests.swift
//  DevLogPresentationTests
//
//  Created by opfic on 4/6/26.
//

import Testing
import Foundation
import DevLogDomain
@testable import DevLogPresentation

@MainActor
struct DeletePushNotificationTests {
    @Test("삭제하면 항목이 즉시 숨겨지고 되돌리기 토스트가 표시되며 삭제 유스케이스가 호출된다")
    func 삭제하면_항목이_즉시_숨겨지고_되돌리기_토스트가_표시되며_삭제_유스케이스가_호출된다() async throws {
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

        #expect(pushNotificationListViewModel.state.notifications.filter { !$0.isHidden }.isEmpty)
        #expect(pushNotificationListViewModel.state.showToast)

        await waitUntil {
            deletePushNotificationUseCaseSpy.calledNotificationIds == ["notification-1"]
        }

        #expect(deletePushNotificationUseCaseSpy.calledNotificationIds == ["notification-1"])
    }

    @Test("삭제를 되돌리면 되돌리기 유스케이스가 호출되고 숨김 상태가 해제된다")
    func 삭제를_되돌리면_되돌리기_유스케이스가_호출되고_숨김_상태가_해제된다() async throws {
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

        let restoredPushNotificationItem = try #require(
            pushNotificationListViewModel.state.notifications.first {
                $0.id == "notification-1"
            }
        )

        #expect(undoDeletePushNotificationUseCaseSpy.calledNotificationIds == ["notification-1"])
        #expect(!restoredPushNotificationItem.isHidden)
    }
}
