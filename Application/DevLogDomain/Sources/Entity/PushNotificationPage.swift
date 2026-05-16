//
//  PushNotificationPage.swift
//  DevLogDomain
//
//  Created by opfic on 2/18/26.
//

import Foundation

public struct PushNotificationPage: Equatable {
    public let items: [PushNotification]
    public let nextCursor: PushNotificationCursor?

    public init(
        items: [PushNotification],
        nextCursor: PushNotificationCursor?
    ) {
        self.items = items
        self.nextCursor = nextCursor
    }

    public static func == (lhs: PushNotificationPage, rhs: PushNotificationPage) -> Bool {
        lhs.items.map { $0.id } == rhs.items.map { $0.id } && lhs.nextCursor == rhs.nextCursor
    }
}
