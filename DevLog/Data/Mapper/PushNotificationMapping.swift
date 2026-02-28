//
//  PushNotificationMapping.swift
//  DevLog
//
//  Created by 최윤진 on 2/27/26.
//

extension PushNotificationResponse {
    func toDomain() throws -> PushNotification {
        guard let id = self.id else {
            throw DataError.invalidData("PushNotificationResponse.id is nil")
        }
        guard let todoKind = TodoKind(rawValue: self.todoKind) else {
            throw DataError.invalidData("PushNotificationResponse.todoKind is invalid: \(self.todoKind)")
        }

        return PushNotification(
            id: id,
            title: self.title,
            body: self.body,
            receivedAt: self.receivedAt,
            isRead: self.isRead,
            todoID: self.todoID,
            todoKind: todoKind
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
