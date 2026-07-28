//
//  PushNotificationListFeatureTests.swift
//  NotificationTabTests
//
//  Created by opfic on 6/12/26.
//

import Combine
import Foundation
import Testing
import Core
import Domain
@testable import NotificationTab

@MainActor
struct PushNotificationListFeatureTests {
    @Test("시간 필터는 query 기준 Date로 threshold를 계산한다")
    func 시간_필터는_query_기준_Date로_threshold를_계산한다() {
        let referenceDate = Date(timeIntervalSince1970: 100_000)

        #expect(
            PushNotificationQuery.TimeFilter.hours(24)
                .thresholdDate(relativeTo: referenceDate)
                == referenceDate.addingTimeInterval(-86_400)
        )
    }

    @Test("refresh는 기준 Date를 갱신한 query로 첫 페이지를 조회한다")
    func refresh는_기준_Date를_갱신한_query로_첫_페이지를_조회한다() async {
        let referenceDate = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 2_000)
        let query = PushNotificationQuery(
            sortOrder: .latest,
            timeFilter: .hours(24),
            unreadOnly: false,
            pageSize: 20,
            referenceDate: referenceDate
        )
        let querySpy = FetchPushNotificationQueryUseCaseSpy()
        querySpy.pushNotificationQuery = query
        let fetchSpy = PushNotificationListFetchUseCaseSpy(pages: [
            PushNotificationPage(items: [], nextCursor: nil)
        ])
        let adapter = PushNotificationListStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchQueryUseCase: querySpy,
            now: now
        )

        await adapter.refresh()

        let refreshedQuery = adapter.query
        #expect(refreshedQuery.referenceDate == now)
        #expect(fetchSpy.queries == [refreshedQuery])
        #expect(fetchSpy.cursors == [nil])
    }

    @Test("refresh 후 listener는 조회와 같은 기준 Date를 사용한다")
    func refresh_후_listener는_조회와_같은_기준_Date를_사용한다() async {
        let subject = PassthroughSubject<PushNotificationPage, Error>()
        let referenceDate = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 2_000)
        let query = PushNotificationQuery(
            sortOrder: .latest,
            timeFilter: .hours(24),
            unreadOnly: false,
            pageSize: 20,
            referenceDate: referenceDate
        )
        let querySpy = FetchPushNotificationQueryUseCaseSpy()
        querySpy.pushNotificationQuery = query
        let fetchSpy = PushNotificationListFetchUseCaseSpy(
            pages: [PushNotificationPage(items: [], nextCursor: nil)],
            observePublisher: subject.eraseToAnyPublisher()
        )
        let adapter = PushNotificationListStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchQueryUseCase: querySpy,
            now: now
        )

        await adapter.refresh()
        await adapter.startObserving()

        let refreshedQuery = adapter.query
        #expect(fetchSpy.queries == [refreshedQuery])
        #expect(fetchSpy.observedQueries == [refreshedQuery])
        #expect(fetchSpy.observedLimits == [refreshedQuery.pageSize])

        subject.send(completion: .finished)
        await adapter.finishEffects()
    }

    @Test("refresh 실패와 관계없이 기준 Date를 갱신한다")
    func refresh_실패와_관계없이_기준_Date를_갱신한다() async {
        struct DummyError: Error {}

        let referenceDate = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 2_000)
        let query = PushNotificationQuery(
            sortOrder: .latest,
            timeFilter: .hours(24),
            unreadOnly: false,
            pageSize: 20,
            referenceDate: referenceDate
        )
        let querySpy = FetchPushNotificationQueryUseCaseSpy()
        querySpy.pushNotificationQuery = query
        let fetchSpy = PushNotificationListFetchUseCaseSpy()
        fetchSpy.error = DummyError()
        let adapter = PushNotificationListStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchQueryUseCase: querySpy,
            now: now
        )

        await adapter.refresh()

        #expect(adapter.query.referenceDate == now)
    }

    @Test("fetchNotifications는 첫 페이지를 조회하고 목록과 hasMore 상태를 갱신한다")
    func fetchNotifications는_첫_페이지를_조회하고_목록과_hasMore_상태를_갱신한다() async throws {
        let cursor = makePushNotificationCursor(documentID: "cursor-1")
        let notifications = (0..<20).map {
            makePushNotification(id: "notification-\($0)", number: $0, isRead: $0.isMultiple(of: 2))
        }
        let fetchSpy = PushNotificationListFetchUseCaseSpy(pages: [
            PushNotificationPage(items: notifications, nextCursor: cursor)
        ])
        let adapter = PushNotificationListStoreTestAdapter(fetchUseCase: fetchSpy)

        try await verifyFetchNotifications(adapter: adapter, fetchUseCaseSpy: fetchSpy)
    }

    @Test("loadNextPage는 다음 커서로 조회한 알림을 기존 목록 뒤에 추가한다")
    func loadNextPage는_다음_커서로_조회한_알림을_기존_목록_뒤에_추가한다() async throws {
        let cursor = makePushNotificationCursor(documentID: "cursor-1")
        let firstPage = (0..<20).map {
            makePushNotification(id: "notification-\($0)", number: $0)
        }
        let nextNotification = makePushNotification(id: "notification-next", number: 20)
        let fetchSpy = PushNotificationListFetchUseCaseSpy(pages: [
            PushNotificationPage(items: firstPage, nextCursor: cursor),
            PushNotificationPage(items: [nextNotification], nextCursor: nil)
        ])
        let adapter = PushNotificationListStoreTestAdapter(fetchUseCase: fetchSpy)

        try await verifyLoadNextPage(
            adapter: adapter,
            fetchUseCaseSpy: fetchSpy,
            nextNotification: nextNotification
        )
    }

    @Test("필터 액션은 query와 적용 필터 수를 갱신한다")
    func 필터_액션은_query와_적용_필터_수를_갱신한다() async throws {
        let now = Date(timeIntervalSince1970: 2_000)
        let updateSpy = UpdatePushNotificationQueryUseCaseSpy()
        let adapter = PushNotificationListStoreTestAdapter(
            updateQueryUseCase: updateSpy,
            now: now
        )

        try await verifyFilterStateTransitions(
            adapter: adapter,
            updateQueryUseCaseSpy: updateSpy,
            referenceDate: now
        )
    }

    @Test("selectNotification은 선택 상태를 바꾸고 읽지 않은 알림을 읽음 처리한다")
    func selectNotification은_선택_상태를_바꾸고_읽지_않은_알림을_읽음_처리한다() async throws {
        let fetchSpy = PushNotificationListFetchUseCaseSpy(pages: [
            PushNotificationPage(
                items: [
                    makePushNotification(id: "notification-1", number: 1, isRead: false)
                ],
                nextCursor: nil
            )
        ])
        let toggleSpy = TogglePushNotificationReadUseCaseSpy()
        let adapter = PushNotificationListStoreTestAdapter(
            fetchUseCase: fetchSpy,
            toggleReadUseCase: toggleSpy
        )

        try await verifySelectNotification(
            adapter: adapter,
            toggleReadUseCaseSpy: toggleSpy
        )
    }

    @Test("toggleRead는 알림 읽음 상태를 토글하고 유스케이스를 호출한다")
    func toggleRead는_알림_읽음_상태를_토글하고_유스케이스를_호출한다() async throws {
        let fetchSpy = PushNotificationListFetchUseCaseSpy(pages: [
            PushNotificationPage(
                items: [
                    makePushNotification(id: "notification-1", number: 1, isRead: true)
                ],
                nextCursor: nil
            )
        ])
        let toggleSpy = TogglePushNotificationReadUseCaseSpy()
        let adapter = PushNotificationListStoreTestAdapter(
            fetchUseCase: fetchSpy,
            toggleReadUseCase: toggleSpy
        )

        try await verifyToggleRead(
            adapter: adapter,
            toggleReadUseCaseSpy: toggleSpy
        )
    }

    @Test("toggleRead 실패 시 읽음 상태를 원래 값으로 롤백한다")
    func toggleRead_실패_시_읽음_상태를_원래_값으로_롤백한다() async throws {
        struct DummyError: Error {}

        let fetchSpy = PushNotificationListFetchUseCaseSpy(pages: [
            PushNotificationPage(
                items: [
                    makePushNotification(id: "notification-1", number: 1, isRead: true)
                ],
                nextCursor: nil
            )
        ])
        let toggleSpy = TogglePushNotificationReadUseCaseSpy()
        toggleSpy.error = DummyError()
        let adapter = PushNotificationListStoreTestAdapter(
            fetchUseCase: fetchSpy,
            toggleReadUseCase: toggleSpy
        )

        await adapter.fetchNotifications()
        let item = try #require(adapter.notifications.first)

        await adapter.toggleRead(item)

        #expect(adapter.notifications.first?.isRead == true)
    }

    @Test("syncSheetPresentation은 layout에 따라 시트 상태를 동기화한다")
    func syncSheetPresentation은_layout에_따라_시트_상태를_동기화한다() async throws {
        let fetchSpy = PushNotificationListFetchUseCaseSpy(pages: [
            PushNotificationPage(
                items: [
                    makePushNotification(id: "notification-1", number: 1, isRead: true)
                ],
                nextCursor: nil
            )
        ])
        let adapter = PushNotificationListStoreTestAdapter(fetchUseCase: fetchSpy)

        await adapter.fetchNotifications()
        await adapter.selectNotification("notification-1")

        await adapter.syncSheetPresentation(isCompactLayout: true)

        #expect(adapter.sheetTodoId == "todo-1")

        await adapter.syncSheetPresentation(isCompactLayout: false)

        #expect(adapter.sheetTodoId == nil)
        #expect(adapter.selectedNotificationId == "notification-1")
        #expect(adapter.selectedTodoId?.id == "todo-1")

        await adapter.syncSheetPresentation(isCompactLayout: true)

        #expect(adapter.sheetTodoId == "todo-1")

        await adapter.dismissSheet()

        #expect(adapter.sheetTodoId == nil)
        #expect(adapter.selectedNotificationId == nil)
        #expect(adapter.selectedTodoId == nil)
    }

    @Test("delete와 undoDelete는 숨김 상태와 최종 제거 상태를 제어한다")
    func delete와_undoDelete는_숨김_상태와_최종_제거_상태를_제어한다() async throws {
        let fetchSpy = PushNotificationListFetchUseCaseSpy(pages: [
            PushNotificationPage(
                items: [makePushNotification(id: "notification-1", number: 1)],
                nextCursor: nil
            )
        ])
        let deleteSpy = DeletePushNotificationUseCaseSpy()
        let undoSpy = UndoDeletePushNotificationUseCaseSpy()
        let adapter = PushNotificationListStoreTestAdapter(
            fetchUseCase: fetchSpy,
            deleteUseCase: deleteSpy,
            undoDeleteUseCase: undoSpy
        )

        try await verifyDeleteUndoAndFinishToast(
            adapter: adapter,
            deleteUseCaseSpy: deleteSpy,
            undoDeleteUseCaseSpy: undoSpy
        )
    }
}
