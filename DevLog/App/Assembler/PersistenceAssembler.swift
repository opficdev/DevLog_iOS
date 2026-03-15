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
    }
}
