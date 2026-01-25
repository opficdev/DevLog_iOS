//
//  PushNotificationSettings.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation

struct PushNotificationSettings: Equatable {
    let isEnabled: Bool
    let scheduledTime: DateComponents
}
