//
//  PushNotificationListTestSpies.swift
//  NotificationTabTests
//
//  Created by opfic on 7/6/26.
//

import Core
import Domain

final class DeletePushNotificationUseCaseSpy: DeletePushNotificationUseCase {
    private(set) var calledNotificationIds = [String]()

    func execute(_ notificationID: String) async throws {
        calledNotificationIds.append(notificationID)
    }
}

final class UndoDeletePushNotificationUseCaseSpy: UndoDeletePushNotificationUseCase {
    private(set) var calledNotificationIds = [String]()

    func execute(_ notificationID: String) async throws {
        calledNotificationIds.append(notificationID)
    }
}

final class TogglePushNotificationReadUseCaseSpy: TogglePushNotificationReadUseCase {
    private(set) var calledTodoIds = [String]()
    var error: Error?

    func execute(_ todoId: String) async throws {
        calledTodoIds.append(todoId)
        if let error {
            throw error
        }
    }
}

final class FetchPushNotificationQueryUseCaseSpy: FetchPushNotificationQueryUseCase {
    var pushNotificationQuery = PushNotificationQuery.default

    func execute() -> PushNotificationQuery {
        pushNotificationQuery
    }
}

final class UpdatePushNotificationQueryUseCaseSpy: UpdatePushNotificationQueryUseCase {
    private(set) var queries = [PushNotificationQuery]()

    func execute(_ query: PushNotificationQuery) {
        queries.append(query)
    }
}
