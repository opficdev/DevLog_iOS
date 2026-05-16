//
//  PersistenceAssembler.swift
//  DevLogPersistence
//
//  Created by opfic on 3/15/26.
//

import DevLogCore
import DevLogData
import DevLogWidgetCore

public final class PersistenceAssembler: Assembler {
    public init() { }

    public func assemble(_ container: any DIContainer) {
        container.register(UserDefaultsStore.self) {
            UserDefaultsStoreImpl()
        }

        container.register(ThemeStore.self) {
            ThemeStoreImpl()
        }

        container.register(WebPageImageStore.self) {
            WebPageImageStoreImpl()
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
    }
}
