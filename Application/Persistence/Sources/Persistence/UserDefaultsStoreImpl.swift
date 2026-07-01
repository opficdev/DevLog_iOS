//
//  UserDefaultsStoreImpl.swift
//  Persistence
//
//  Created by 최윤진 on 2/25/26.
//

import Foundation
import Data

final class UserDefaultsStoreImpl: UserDefaultsStore {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    func value<T: Codable>(forKey key: String) -> T? {
        let decoder = JSONDecoder()
        guard let data = userDefaults.data(forKey: key) else { return nil }
        guard let value = try? decoder.decode(T.self, from: data) else {
            userDefaults.removeObject(forKey: key)
            return nil
        }
        return value
    }

    func setValue<T: Codable>(_ value: T?, forKey key: String) {
        let encoder = JSONEncoder()
        guard let value else {
            userDefaults.removeObject(forKey: key)
            return
        }

        guard let data = try? encoder.encode(value) else { return }
        userDefaults.set(data, forKey: key)
    }

    func removeValues(withPrefix prefix: String) {
        userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .forEach(userDefaults.removeObject(forKey:))
    }

    func setString(_ value: String?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func stringArray(forKey key: String) -> [String] {
        userDefaults.stringArray(forKey: key) ?? []
    }

    func setStringArray(_ value: [String], forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: key)
    }

    func setBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
}
