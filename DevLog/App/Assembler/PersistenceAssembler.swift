//
//  PersistenceAssembler.swift
//  DevLog
//
//  Created by opfic on 3/15/26.
//

final class PersistenceAssembler: Assembler {
    func assemble(_ container: any DIContainer) {
        container.register(UserDefaultsStore.self) {
            UserDefaultsStore()
        }

        container.register(ThemeStore.self) {
            ThemeStore()
        }

        container.register(WebPageImageStore.self) {
            WebPageImageStore()
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
            WidgetSnapshotPreferenceStore()
        }

        container.register(WidgetSnapshotUpdater.self) {
            WidgetSnapshotUpdater(
                snapshotStore: container.resolve(WidgetSnapshotStore.self),
                preferenceStore: container.resolve(WidgetSnapshotPreferenceStore.self)
            )
        }
    }
}
