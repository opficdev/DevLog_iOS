//
//  PersistenceAssembler.swift
//  Persistence
//
//  Created by opfic on 3/15/26.
//

import Core
import Data

public final class PersistenceAssembler: Assembler {
    public init() { }

    public func assemble(_ container: any DIContainer) {
        container.register(UserDefaultsStore.self) {
            UserDefaultsStoreImpl()
        }

        container.register(MemoryCacheStore.self) {
            MemoryCacheStoreImpl()
        }

        container.register(ThemeStore.self) {
            ThemeStoreImpl()
        }

        container.register(WebPageImageStore.self) {
            WebPageImageStoreImpl()
        }
    }
}
