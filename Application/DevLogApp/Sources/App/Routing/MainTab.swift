//
//  MainTab.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Foundation

enum MainTab: Hashable {
    case home
    case today
    case notification
    case profile

    init?(widgetURL: URL) {
        guard widgetURL.scheme?.lowercased() == WidgetDeepLink.scheme.lowercased() else { return nil }

        switch widgetURL.host {
        case WidgetDeepLink.todayTodoHost:
            self = .today
        case WidgetDeepLink.heatmapHost:
            self = .profile
        default:
            return nil
        }
    }
}
