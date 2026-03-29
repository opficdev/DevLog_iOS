//
//  PushNotificationMapping.swift
//  DevLog
//
//  Created by 최윤진 on 2/27/26.
//

extension PushNotificationResponse {
    func toDomain() throws -> PushNotification {
        guard let todoCategory = SystemTodoCategory(rawValue: self.todoCategory) else {
            throw DataError.invalidData("PushNotificationResponse.todoCategory is invalid: \(self.todoCategory)")
        }

        return PushNotification(
            id: id,
            title: self.title,
            body: self.body,
            receivedAt: self.receivedAt,
            isRead: self.isRead,
            todoId: self.todoId,
            todoCategory: .system(todoCategory)
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
