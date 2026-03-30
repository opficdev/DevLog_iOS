//
//  PushNotificationRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 1/18/26.
//

import Foundation
import Combine

final class PushNotificationRepositoryImpl: PushNotificationRepository {
    private let pushNotificationService: PushNotificationService
    private let todoCategoryService: TodoCategoryService

    init(
        pushNotificationService: PushNotificationService,
        todoCategoryService: TodoCategoryService
    ) {
        self.pushNotificationService = pushNotificationService
        self.todoCategoryService = todoCategoryService
    }

    /// 푸시 알림 On/Off 설정
    func fetchPushNotificationEnabled() async throws -> Bool {
        return try await pushNotificationService.fetchPushNotificationEnabled()
    }

    /// 푸시 알림 시간 설정
    func fetchPushNotificationTime() async throws -> DateComponents {
        return try await pushNotificationService.fetchPushNotificationTime()
    }

    /// 푸시 알림 설정 업데이트
    func updatePushNotificationSettings(_ settings: PushNotificationSettings) async throws {
        try await pushNotificationService.updatePushNotificationSettings(
            isEnabled: settings.isEnabled, components: settings.scheduledTime
        )
    }

    /// 푸시 알림 기록 요청
    func requestNotifications(
        _ query: PushNotificationQuery,
        cursor: PushNotificationCursor?
    ) async throws -> PushNotificationPage {
        let cursorDTO = cursor.map { PushNotificationCursorDTO.fromDomain($0) }
        async let responseTask = pushNotificationService.requestNotifications(query, cursor: cursorDTO)
        async let preferencesTask = todoCategoryService.fetchPreferences()

        let (response, preferences) = try await (responseTask, preferencesTask)
        let userTodoCategories: [UserTodoCategory] = preferences.compactMap { preference in
            guard case .user(let userTodoCategory) = preference.category else {
                return nil
            }

            return userTodoCategory
        }

        let responses = try response.items.map {
            try resolve($0, userTodoCategories: userTodoCategories)
        }

        return try PushNotificationPageResponse(
            items: responses,
            nextCursor: response.nextCursor
        ).toDomain()
    }

    func observeNotifications(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPage, Error> {
        let subject = PassthroughSubject<PushNotificationPage, Error>()
        var cancellable: AnyCancellable?

        cancellable = try pushNotificationService.observeNotifications(query, limit: limit)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        subject.send(completion: .finished)
                    case .failure(let error):
                        subject.send(completion: .failure(error))
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self else { return }

                    Task {
                        do {
                            let preferences = try await self.todoCategoryService.fetchPreferences()
                            let userTodoCategories: [UserTodoCategory] = preferences.compactMap { preference in
                                guard case .user(let userTodoCategory) = preference.category else {
                                    return nil
                                }

                                return userTodoCategory
                            }

                            let responses = try response.items.map {
                                try self.resolve($0, userTodoCategories: userTodoCategories)
                            }

                            let page = try PushNotificationPageResponse(
                                items: responses,
                                nextCursor: response.nextCursor
                            ).toDomain()

                            subject.send(page)
                        } catch {
                            subject.send(completion: .failure(error))
                        }
                    }
                }
            )

        return subject
            .handleEvents(receiveCancel: { cancellable?.cancel() })
            .eraseToAnyPublisher()
    }

    func observeUnreadPushCount() throws -> AnyPublisher<Int, Error> {
        try pushNotificationService.observeUnreadPushCount()
            .eraseToAnyPublisher()
    }

    // 푸시 알림 기록 삭제
    func deleteNotification(_ notificationID: String) async throws {
        try await pushNotificationService.deleteNotification(notificationID)
    }

    func undoDeleteNotification(_ notificationID: String) async throws {
        try await pushNotificationService.undoDeleteNotification(notificationID)
    }

    // 푸시 알림 읽음/안읽음 토글
    func toggleNotificationRead(_ todoId: String) async throws {
        try await pushNotificationService.toggleNotificationRead(todoId)
    }
}

private extension PushNotificationRepositoryImpl {
    func resolve(
        _ response: PushNotificationResponse,
        userTodoCategories: [UserTodoCategory]
    ) throws -> PushNotificationResponse {
        let categoryName: String
        switch response.todoCategory {
        case .raw(let rawValue):
            categoryName = rawValue
        case .decoded:
            return response
        }

        let todoCategory: TodoCategory
        if let systemTodoCategory = SystemTodoCategory(rawValue: categoryName) {
            todoCategory = .system(systemTodoCategory)
        } else if let userTodoCategory = userTodoCategories.first(where: {
            $0.name == categoryName
        }) {
            todoCategory = .user(userTodoCategory)
        } else {
            throw DataError.invalidData("PushNotificationResponse.todoCategory is invalid: \(categoryName)")
        }

        return PushNotificationResponse(
            id: response.id,
            title: response.title,
            body: response.body,
            receivedAt: response.receivedAt,
            isRead: response.isRead,
            todoId: response.todoId,
            todoCategory: .decoded(todoCategory)
        )
    }
}
