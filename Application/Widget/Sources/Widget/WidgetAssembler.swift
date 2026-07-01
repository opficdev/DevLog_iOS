//
//  WidgetAssembler.swift
//  Widget
//
//  Created by opfic on 6/8/26.
//

import Core
import Data
import WidgetCore

public final class WidgetAssembler: Assembler {
    public init() { }

    public func assemble(_ container: any DIContainer) {
        container.register(AuthSessionStateProvider.self) {
            AuthSessionStateProviderImpl()
        }

        container.register(WidgetSyncEventBus.self) {
            WidgetSyncEventBusImpl()
        }
        container.register(WidgetSharedDefaultsStore.self) {
            WidgetSharedDefaultsStore()
        }
        container.register(WidgetSnapshotStore.self) {
            WidgetSnapshotStore(
                store: container.resolve(WidgetSharedDefaultsStore.self)
            )
        }
        container.register(WidgetSnapshotPreferenceStore.self) {
            WidgetSnapshotPreferenceStoreImpl()
        }
        container.register(WidgetSnapshotUpdater.self) {
            WidgetSnapshotUpdaterImpl(
                snapshotStore: container.resolve(WidgetSnapshotStore.self),
                preferenceStore: container.resolve(WidgetSnapshotPreferenceStore.self)
            )
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
