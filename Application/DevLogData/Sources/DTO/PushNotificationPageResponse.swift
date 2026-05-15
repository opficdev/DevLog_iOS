//
//  PushNotificationPageResponse.swift
//  DevLog
//
//  Created by opfic on 2/18/26.
//

public struct PushNotificationPageResponse {
    public let items: [PushNotificationResponse]
    public let nextCursor: PushNotificationCursorDTO?

    public init(
        items: [PushNotificationResponse],
        nextCursor: PushNotificationCursorDTO?
    ) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
