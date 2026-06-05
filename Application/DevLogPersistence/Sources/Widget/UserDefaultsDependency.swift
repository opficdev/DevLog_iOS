//
//  UserDefaultsDependency.swift
//  DevLogPersistence
//
//  Created by opfic on 6/5/26.
//

import Foundation

struct UserDefaultsDependency: @unchecked Sendable {
    private let value: UserDefaults

    init(value: UserDefaults) {
        self.value = value
    }

    func stringArray(forKey key: String) -> [String]? {
        value.stringArray(forKey: key)
    }

    func string(forKey key: String) -> String? {
        value.string(forKey: key)
    }

    func set(_ value: Any?, forKey key: String) {
        self.value.set(value, forKey: key)
    }

    func removeObject(forKey key: String) {
        value.removeObject(forKey: key)
    }
}
