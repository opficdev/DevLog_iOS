//
//  WidgetSharedDefaultsStore.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation
import DevLogDomain
import DevLogData

public final class WidgetSharedDefaultsStore {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = UserDefaults(suiteName: WidgetAppGroup.identifier) ?? .standard) {
        self.userDefaults = userDefaults
    }

    func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: key)
    }

    func setData(_ value: Data?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
