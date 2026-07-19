//
//  PushNotificationRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 7/19/26.
//

import Combine
import Foundation
import Testing
import Core
import Domain
@testable import Data

struct PushNotificationRepositoryImplTests {
    @Test("푸시 알림 카테고리 해석은 의미 기반 내용을 보존한다")
    func 푸시_알림_카테고리_해석은_의미_기반_내용을_보존한다() async throws {
        let response = PushNotificationResponse(
            id: "notification-id",
            title: "fallback-title",
            body: "fallback-body",
            receivedAt: Date(timeIntervalSince1970: 1),
            isRead: false,
            todoId: "todo-id",
            todoCategory: .raw(SystemTodoCategory.feature.rawValue),
            content: .todoDueTomorrow(todoTitle: "테스트 작성")
        )
        let service = PushNotificationServiceSpy(response: response)
        let repository = PushNotificationRepositoryImpl(
            pushNotificationService: service,
            todoCategoryService: TodoCategoryServiceSpy(),
            store: MemoryCacheStoreSpy()
        )

        let page = try await repository.requestNotifications(.default, cursor: nil)
        let notification = try #require(page.items.first)

        #expect(notification.content == .todoDueTomorrow(todoTitle: "테스트 작성"))
        #expect(notification.todoCategory == .system(.feature))
    }
}

private final class PushNotificationServiceSpy: PushNotificationService {
    private let response: PushNotificationResponse

    init(response: PushNotificationResponse) {
        self.response = response
    }

    func fetchPushNotificationEnabled() async throws -> Bool { false }
    func fetchPushNotificationTime() async throws -> DateComponents { DateComponents() }
    func updatePushNotificationSettings(isEnabled: Bool, components: DateComponents) async throws { }

    func requestNotifications(
        _ notificationQuery: PushNotificationQuery,
        cursor: PushNotificationCursorDTO?
    ) async throws -> PushNotificationPageResponse {
        PushNotificationPageResponse(items: [response], nextCursor: nil)
    }

    func observeNotifications(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPageResponse, Error> {
        Empty().eraseToAnyPublisher()
    }

    func observeUnreadPushCount() throws -> AnyPublisher<Int, Error> {
        Empty().eraseToAnyPublisher()
    }

    func deleteNotification(_ notificationID: String) async throws { }
    func undoDeleteNotification(_ notificationID: String) async throws { }
    func toggleNotificationRead(_ todoId: String) async throws { }
}

private final class TodoCategoryServiceSpy: TodoCategoryService {
    func fetchCategoryPreferences() async throws -> [TodoCategoryPreferenceResponse] { [] }
    func updateCategoryPreferences(_ preferences: [TodoCategoryPreferenceResponse]) async throws { }
}

private final class MemoryCacheStoreSpy: MemoryCacheStore {
    func value<Value: Codable>(forKey key: String) -> Value? { nil }
    func setValue<Value: Codable>(_ value: Value?, forKey key: String) { }
}
