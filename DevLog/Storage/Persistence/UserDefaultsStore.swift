//
//  UserDefaultsStore.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Foundation

final class UserDefaultsStore {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
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

    func removeAll() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        let firstLaunch = userDefaults.object(forKey: "isFirstLaunch")
        userDefaults.removePersistentDomain(forName: bundleIdentifier)
        if let firstLaunch {
            userDefaults.set(firstLaunch, forKey: "isFirstLaunch")
        }
    }
}
