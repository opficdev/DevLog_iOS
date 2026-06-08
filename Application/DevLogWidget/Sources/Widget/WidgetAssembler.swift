//
//  WidgetAssembler.swift
//  DevLogWidget
//
//  Created by opfic on 6/8/26.
//

import DevLogCore
import DevLogData

public final class WidgetAssembler: Assembler {
    public init() { }

    public func assemble(_ container: any DIContainer) {
        container.register(AuthSessionStateProvider.self) {
            AuthSessionStateProviderImpl()
        }

        container.register(WidgetSyncEventBus.self) {
            WidgetSyncEventBusImpl()
        }
        container.register(WidgetSyncEventHandler.self) {
            WidgetSyncEventHandler(
                eventBus: container.resolve(WidgetSyncEventBus.self),
                repository: container.resolve(WidgetTodoSnapshotRepository.self),
                snapshotUpdater: container.resolve(WidgetSnapshotUpdater.self)
            )
        }
        container.register(WidgetSessionSyncHandler.self) {
            WidgetSessionSyncHandler(
                provider: container.resolve(AuthSessionStateProvider.self),
                widgetSyncEventBus: container.resolve(WidgetSyncEventBus.self)
            )
        }
    }
}
