//
//  WidgetDeepLink.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Foundation

enum WidgetDeepLink {
    static let scheme = "DevLog"
    static let todayTodoHost = "today"
    static let heatmapHost = "profile"

    static var todayTodoURL: URL? {
        url(host: todayTodoHost)
    }

    static var heatmapURL: URL? {
        url(host: heatmapHost)
    }

    private static func url(host: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        return urlComponents.url
    }
}
