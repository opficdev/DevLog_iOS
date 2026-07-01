//
//  PushNotificationCursorDTO.swift
//  Data
//
//  Created by 최윤진 on 2/27/26.
//

import Foundation
import Domain

public struct PushNotificationCursorDTO {
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
