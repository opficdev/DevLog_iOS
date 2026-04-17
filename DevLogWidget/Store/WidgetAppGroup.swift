//
//  WidgetAppGroup.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import Foundation

enum WidgetAppGroup {
    static let identifier = "group.opfic.DevLog"
}

enum WidgetSharedUserDefaults {
    static let shared = UserDefaults(suiteName: WidgetAppGroup.identifier)
}
