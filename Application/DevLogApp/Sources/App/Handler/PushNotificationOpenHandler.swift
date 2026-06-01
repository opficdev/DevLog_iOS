//
//  PushNotificationOpenHandler.swift
//  DevLog
//
//  Created by opfic on 5/28/26.
//

import Foundation
import DevLogData

final class PushNotificationOpenHandler {
    private let analyticsService: AnalyticsService

    init(analyticsService: AnalyticsService) {
        self.analyticsService = analyticsService
    }

    func handlePushOpen(userInfo: [AnyHashable: Any]) {
        analyticsService.trackPushOpen()
        PushNotificationRoute.shared.handlePushTap(userInfo: userInfo)
    }
}
