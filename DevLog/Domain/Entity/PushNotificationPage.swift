//
//  PushNotificationPage.swift
//  DevLog
//
//  Created by opfic on 2/18/26.
//

import Foundation

struct PushNotificationPage: Equatable {
    let items: [PushNotification]
    let nextCursor: PushNotificationCursor?

    static func == (lhs: PushNotificationPage, rhs: PushNotificationPage) -> Bool {
        lhs.items.map { $0.id } == rhs.items.map { $0.id } && lhs.nextCursor == rhs.nextCursor
    }
}
