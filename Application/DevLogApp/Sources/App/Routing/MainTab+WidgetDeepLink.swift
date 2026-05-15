//
//  MainTab+WidgetDeepLink.swift
//  DevLog
//
//  Created by opfic on 5/15/26.
//

import Foundation
import DevLogPresentation
import DevLogWidgetShared

extension MainTab {
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
