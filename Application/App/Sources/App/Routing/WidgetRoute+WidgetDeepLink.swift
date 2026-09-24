//
//  WidgetRoute+WidgetDeepLink.swift
//  DevLog
//
//  Created by opfic on 9/24/26.
//

import Foundation
import Presentation
import WidgetCore

extension WidgetRoute {
    init?(widgetURL: URL) {
        guard let destination = WidgetDeepLink.destination(for: widgetURL) else { return nil }

        switch destination {
        case .today:
            self = .tab(.today)
        case .profile:
            self = .tab(.profile)
        case .todo(let id):
            self = .todayTodo(id)
        }
    }
}
