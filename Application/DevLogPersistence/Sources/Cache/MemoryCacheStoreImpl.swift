//
//  MemoryCacheStoreImpl.swift
//  DevLogPersistence
//
//  Created by opfic on 6/9/26.
//

import Foundation
import DevLogData

final class MemoryCacheStoreImpl: MemoryCacheStore {
    private let queue = DispatchQueue(
        label: "devlog.memory-cache-store",
        qos: .utility
    )
    private var values = [String: Data]()

    func value<T: Codable>(forKey key: String) -> T? {
        queue.sync {
            let decoder = JSONDecoder()
            guard let data = self.values[key] else { return nil }
            return try? decoder.decode(T.self, from: data)
        }
    }

    func setValue<T: Codable>(_ value: T?, forKey key: String) {
        queue.sync {
            let encoder = JSONEncoder()
            guard let value else {
                self.values.removeValue(forKey: key)
                return
            }

            guard let data = try? encoder.encode(value) else { return }
            self.values[key] = data
        }
    }
}
