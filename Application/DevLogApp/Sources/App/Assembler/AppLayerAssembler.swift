//
//  AppLayerAssembler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import DevLogCore
import DevLogData
import DevLogDomain

final class AppLayerAssembler: Assembler {
    func assemble(_ container: any DIContainer) {
        container.register(WidgetSyncEventBus.self) {
            WidgetSyncEventBusImpl()
        }
        container.register(WidgetSyncEventHandler.self) {
            WidgetSyncEventHandler(
                eventBus: container.resolve(WidgetSyncEventBus.self),
                repository: container.resolve(TodoRepository.self),
                snapshotUpdater: container.resolve(WidgetSnapshotUpdater.self)
            )
        }
        container.register(FCMTokenSyncHandler.self) {
            FCMTokenSyncHandler(
                userService: container.resolve(UserService.self)
            )
        }
        container.register(UserTimeZoneSyncHandler.self) {
            UserTimeZoneSyncHandler(
                userService: container.resolve(UserService.self)
            )
        }
        container.register(PushNotificationOpenHandler.self) {
            PushNotificationOpenHandler(
                trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self)
            )
        }
    }
}
