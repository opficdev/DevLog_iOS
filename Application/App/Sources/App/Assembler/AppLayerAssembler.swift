//
//  AppLayerAssembler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import Core
import Data

final class AppLayerAssembler: Assembler {
    func assemble(_ container: any DIContainer) {
        container.register(FCMTokenSyncHandler.self) {
            FCMTokenSyncHandler(
                authService: container.resolve(AuthService.self),
                messagingService: container.resolve(PushMessagingService.self),
                userService: container.resolve(UserService.self)
            )
        }
        container.register(UserTimeZoneSyncHandler.self) {
            UserTimeZoneSyncHandler(
                authService: container.resolve(AuthService.self),
                userService: container.resolve(UserService.self)
            )
        }
        container.register(PushNotificationOpenHandler.self) {
            PushNotificationOpenHandler(
                analyticsService: container.resolve(AnalyticsService.self)
            )
        }
    }
}
