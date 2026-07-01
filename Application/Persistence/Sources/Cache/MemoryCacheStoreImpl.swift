//
//  MemoryCacheStoreImpl.swift
//  Persistence
//
//  Created by opfic on 6/9/26.
//

import Foundation
import Data

final class MemoryCacheStoreImpl: MemoryCacheStore {
    private let lock = NSLock()
    private var values = [String: Any]()

    func value<T: Codable>(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }

        return values[key] as? T
    }

    func setValue<T: Codable>(_ value: T?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let value else {
            values.removeValue(forKey: key)
            return
        }

        values[key] = value
    }
}
