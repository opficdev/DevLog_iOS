//
//  PushNotificationMapping.swift
//  DevLog
//
//  Created by 최윤진 on 2/27/26.
//

extension PushNotificationResponse {
    func toDomain() throws -> PushNotification {
        let todoCategory: TodoCategory

        switch self.todoCategory {
        case .decoded(let category):
            todoCategory = category
        case .raw(let category):
            throw DataError.invalidData(
                "PushNotificationResponse.todoCategory must be resolved before toDomain(): \(category)"
            )
        }

        return PushNotification(
            id: id,
            title: self.title,
            body: self.body,
            receivedAt: self.receivedAt,
            isRead: self.isRead,
            todoId: self.todoId,
            todoCategory: todoCategory
        )
    }
}

extension PushNotificationCursorDTO {
    func toDomain() -> PushNotificationCursor {
        PushNotificationCursor(
            receivedAt: self.receivedAt,
            documentID: self.documentID
        )
    }

    static func fromDomain(_ cursor: PushNotificationCursor) -> Self {
        PushNotificationCursorDTO(
            receivedAt: cursor.receivedAt,
            documentID: cursor.documentID
        )
    }
}

extension PushNotificationPageResponse {
    func toDomain() throws -> PushNotificationPage {
        let items = try self.items.map { try $0.toDomain() }
        let nextCursor = self.nextCursor?.toDomain()
        return PushNotificationPage(items: items, nextCursor: nextCursor)
    }
}
