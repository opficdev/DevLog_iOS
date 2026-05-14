//
//  UserDefaultsStoreImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Foundation
import DevLogDomain
import DevLogDataCommon
import DevLogDataProtocol
import DevLogPresentation
import DevLogWidgetCore
import DevLogWidgetShared

final class UserDefaultsStoreImpl: UserDefaultsStore {
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
}
