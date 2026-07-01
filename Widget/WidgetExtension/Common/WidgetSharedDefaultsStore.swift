//
//  WidgetSharedDefaultsStore.swift
//  WidgetExtension
//
//  Created by opfic on 4/17/26.
//

import Foundation
import WidgetCore

final class WidgetSharedDefaultsStore {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults(suiteName: WidgetAppGroup.identifier) ?? .standard) {
        self.userDefaults = userDefaults
    }

    func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: key)
    }
}
