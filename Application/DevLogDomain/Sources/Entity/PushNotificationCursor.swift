//
//  PushNotificationCursor.swift
//  DevLog
//
//  Created by opfic on 2/18/26.
//

import Foundation

public struct PushNotificationCursor: Equatable {
    public let receivedAt: Date
    public let documentID: String

    public init(
        receivedAt: Date,
        documentID: String
    ) {
        self.receivedAt = receivedAt
        self.documentID = documentID
    }
}
