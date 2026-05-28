//
//  PushNotificationOpenHandler.swift
//  DevLog
//
//  Created by opfic on 5/28/26.
//

import Foundation
import DevLogDomain

@MainActor
final class PushNotificationOpenHandler {
    private let trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase

    init(trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase) {
        self.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
    }

    func handlePushOpen(userInfo: [AnyHashable: Any]) {
        trackAnalyticsEventUseCase.execute(.pushOpen)
        PushNotificationRoute.shared.handlePushTap(userInfo: userInfo)
    }
}
