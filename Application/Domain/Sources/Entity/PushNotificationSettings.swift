//
//  PushNotificationSettings.swift
//  Domain
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation

public struct PushNotificationSettings: Equatable {
    public let isEnabled: Bool
    public let scheduledTime: DateComponents

    public init(
        isEnabled: Bool,
        scheduledTime: DateComponents
    ) {
        self.isEnabled = isEnabled
        self.scheduledTime = scheduledTime
    }
}
